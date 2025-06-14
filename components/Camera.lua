local _, ns = ...
local mounts, journal, math = ns.mounts, ns.journal, math
local ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL = ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL
local GetScaledCursorDelta, GetScaledCursorPosition = GetScaledCursorDelta, GetScaledCursorPosition
local DeltaLerp, Vector3D_CalculateNormalFromYawPitch, Vector3D_ScaleBy, Vector3D_Add = DeltaLerp, Vector3D_CalculateNormalFromYawPitch, Vector3D_ScaleBy, Vector3D_Add
local pi2 = math.pi * 2


local function setMaxOffsets(self)
	local w, h = self:GetOwningScene():GetSize()
	local hw, hh = w / 2, h / 2
	local extra = 50
	self.xMaxOffset = hw + extra
	self.yMaxOffset = hh + extra
	self.xMaxCursor = self.xMaxOffset / self:GetDeltaModifierForCameraMode(self.buttonModes.rightX) - hw
	self.yMaxCursor = self.yMaxOffset / self:GetDeltaModifierForCameraMode(self.buttonModes.rightY) - hh
end

local function SaveInitialTransform(self)
	local initialLightYaw, initialLightPitch = Vector3D_CalculateYawPitchFromNormal(Vector3D_Normalize(self:GetOwningScene():GetLightDirection()))
	self.lightDeltaYaw = initialLightYaw - self:GetYaw()
	self.lightDeltaPitch = initialLightPitch - self:GetPitch()
end

local function TryCreateZoomSpline(x, y, z, existingSpline)
	if x and y and z and (x ~= 0 or y ~= 0 or z ~= 0) then
		local spline = existingSpline or CreateCatmullRomSpline(3)
		spline:ClearPoints()
		spline:AddPoint(0, 0, 0)
		spline:AddPoint(x, y, z)

		return spline
	end
end

local function ApplyFromModelSceneCameraInfo(self, modelSceneCameraInfo, transitionType, modificationType)
	modelSceneCameraInfo.target.z = modelSceneCameraInfo.target.z - 1.2
	modelSceneCameraInfo.maxZoomDistance = modelSceneCameraInfo.maxZoomDistance + 6

	local transitionalCameraInfo = self:CalculateTransitionalValues(self.modelSceneCameraInfo, modelSceneCameraInfo, modificationType)
	self.modelSceneCameraInfo = modelSceneCameraInfo

	self:SetTarget(transitionalCameraInfo.target:GetXYZ())
	self:SetTargetSpline(TryCreateZoomSpline(transitionalCameraInfo.zoomedTargetOffset:GetXYZ()), self:GetTargetSpline())
	self:SetOrientationSpline(TryCreateZoomSpline(transitionalCameraInfo.zoomedYawOffset, transitionalCameraInfo.zoomedPitchOffset, transitionalCameraInfo.zoomedRollOffset), self:GetOrientationSpline())

	self:SetMinZoomDistance(transitionalCameraInfo.minZoomDistance)
	self:SetMaxZoomDistance(transitionalCameraInfo.maxZoomDistance)

	self:SetZoomDistance(transitionalCameraInfo.zoomDistance)

	self:SetYaw(transitionalCameraInfo.yaw)
	self:SetPitch(transitionalCameraInfo.pitch)
	self:SetRoll(transitionalCameraInfo.roll)

	if self.xOffset == nil then
		self.defYOfsset = 20
		self.yOffsetDelta = 40
		self.xOffset = 0
		self.yOffset = self.defYOfsset + (mounts.config.mountDescriptionToggle and self.yOffsetDelta or 0)
		self.panningXOffset = 0
		self.panningYOffset = self.yOffset
		self:setMaxOffsets()
		self:SaveInitialTransform()
	end

	if transitionType == CAMERA_TRANSITION_TYPE_IMMEDIATE then
		self:SnapAllInterpolatedValues()
	end
	self:UpdateCameraOrientationAndPosition()
end

local function gridApplyFromModelSceneCameraInfo(self, ...)
	ApplyFromModelSceneCameraInfo(self, ...)
	self.yOffset = 18
	self.panningYOffset = self.yOffset
end

local function setAcceleration(self, deltaX, deltaY, elapsed)
	self.accX = deltaX / elapsed * mounts.cameraConfig.xInitialAcceleration
	local xMinInit = 400 * mounts.cameraConfig.xInitialAcceleration
	if self.accX > -xMinInit and self.accX < xMinInit then self.accX = nil end

	self.accY = deltaY / elapsed * mounts.cameraConfig.yInitialAcceleration
	local yMinInit = 400 * mounts.cameraConfig.yInitialAcceleration
	if self.accY > -yMinInit and self.accY < yMinInit then self.accY = nil end
end

local function getDeltaAcceleration(curAcc, elapsed, kAcc, kSpeed)
	local delta = curAcc * elapsed
	delta = delta + elapsed * delta * kAcc
	local newAcc = delta / elapsed
	local minSpeed = 50 * kSpeed

	if curAcc >= 0 and newAcc < 0 or curAcc < 0 and newAcc >= 0 then
		newAcc = 0
	end

	if math.abs(newAcc) < minSpeed then
		newAcc = minSpeed * (curAcc < 0 and -1 or 1)
		return newAcc * elapsed, newAcc
	end

	if newAcc < 5 and newAcc > -5 then return end
	return delta, newAcc
end

local function updateAcceleration(self, elapsed)
	if not mounts.cameraConfig.xAccelerationEnabled then self.accX = nil end
	if not mounts.cameraConfig.yAccelerationEnabled then self.accY = nil end

	if self.accX then
		local deltaX, accX = getDeltaAcceleration(self.accX, elapsed, mounts.cameraConfig.xAcceleration, mounts.cameraConfig.xMinSpeed)
		self.accX = accX
		if deltaX then
			self:HandleMouseMovement(self.buttonModes.leftX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.leftX), not self.buttonModes.leftXinterpolate)
		end
	end

	if self.accY then
		local deltaY, accY = getDeltaAcceleration(self.accY, elapsed, mounts.cameraConfig.yAcceleration, mounts.cameraConfig.yMinSpeed)
		self.accY = accY
		if deltaY then
			self:HandleMouseMovement(self.buttonModes.leftY, deltaY * self:GetDeltaModifierForCameraMode(self.buttonModes.leftY), not self.buttonModes.leftYinterpolate)
		end
	end
end

local oldHandleMouseMovement = OrbitCameraMixin.HandleMouseMovement
local function HandleMouseMovement(self, mode, delta, snapToValue)
	if mode == ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL then
		self.xOffset = self.xOffset + delta

		if self.xOffset > self.xMaxOffset then self.xOffset = self.xMaxOffset
		elseif self.xOffset < -self.xMaxOffset then self.xOffset = -self.xMaxOffset end

		if snapToValue then
			self.panningXOffset = nil
		end
	elseif mode == ORBIT_CAMERA_MOUSE_PAN_VERTICAL then
		self.yOffset = self.yOffset + delta

		if self.yOffset > self.yMaxOffset then self.yOffset = self.yMaxOffset
		elseif self.yOffset < -self.yMaxOffset then self.yOffset = -self.yMaxOffset end

		if snapToValue then
			self.panningYOffset = nil
		end
	else
		oldHandleMouseMovement(self, mode, delta, snapToValue)
	end
end

local function OnUpdate(self, elapsed)
	if self:IsLeftMouseButtonDown() then
		local deltaX, deltaY = GetScaledCursorDelta()
		self:setAcceleration(deltaX, deltaY, elapsed)
		self:HandleMouseMovement(self.buttonModes.leftX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.leftX), not self.buttonModes.leftXinterpolate)
		self:HandleMouseMovement(self.buttonModes.leftY, deltaY * self:GetDeltaModifierForCameraMode(self.buttonModes.leftY), not self.buttonModes.leftYinterpolate)
	elseif self.accX or self.accY then
		self:updateAcceleration(elapsed)
	end

	if self:IsRightMouseButtonDown() then
		local deltaX, deltaY = GetScaledCursorDelta()
		local x, y = GetScaledCursorPosition()
		local modelScene = self:GetOwningScene()
		if deltaX > 0 and x > modelScene:GetLeft() - self.xMaxCursor
		or deltaX < 0 and x < modelScene:GetRight() + self.xMaxCursor then
			self:HandleMouseMovement(self.buttonModes.rightX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.rightX), not self.buttonModes.rightXinterpolate)
		end
		if deltaY > 0 and y > modelScene:GetBottom() - self.yMaxCursor
		or deltaY < 0 and y < modelScene:GetTop() + self.yMaxCursor then
			self:HandleMouseMovement(self.buttonModes.rightY, -deltaY * self:GetDeltaModifierForCameraMode(self.buttonModes.rightY), not self.buttonModes.rightYinterpolate)
		end
	end

	self:UpdateInterpolationTargets(elapsed)
	self:SynchronizeCamera()
end

local function InterpolateDimension(lastValue, targetValue, amount, elapsed)
	return lastValue and DeltaLerp(lastValue, targetValue, amount, elapsed) or targetValue
end

local oldUpdateInterpolationTargets = OrbitCameraMixin.UpdateInterpolationTargets
local function UpdateInterpolationTargets(self, elapsed)
	oldUpdateInterpolationTargets(self, elapsed)
	self.panningXOffset = InterpolateDimension(self.panningXOffset, self.xOffset, .15, elapsed)
	self.panningYOffset = InterpolateDimension(self.panningYOffset, self.yOffset, .15, elapsed)
end

local function UpdateCameraOrientationAndPosition(self)
	local yaw, pitch, roll = self:GetInterpolatedOrientation()
	local modelScene = self:GetOwningScene()
	modelScene:SetCameraOrientationByYawPitchRoll(yaw, pitch, roll)

	local axisAngleX, axisAngleY, axisAngleZ = Vector3D_CalculateNormalFromYawPitch(yaw, pitch)
	local targetX, targetY, targetZ = self:GetInterpolatedTarget()
	local zoomDistance = self:GetInterpolatedZoomDistance()

	-- Panning start --
	-- We want the model to move 1-to-1 with the mouse.
	-- Panning formula: dx / hypotenuse * zoomDistance
	local width, height = modelScene:GetSize()
	local zoomFactor = zoomDistance / math.sqrt(width * width + height * height)

	local rightX, rightY, rightZ = Vector3D_ScaleBy(self.panningXOffset * zoomFactor, self:GetRightVector())
	local upX, upY, upZ = Vector3D_ScaleBy(self.panningYOffset * zoomFactor, self:GetUpVector())
	targetX, targetY, targetZ = Vector3D_Add(targetX, targetY, targetZ, rightX, rightY, rightZ)
	targetX, targetY, targetZ = Vector3D_Add(targetX, targetY, targetZ, upX, upY, upZ)
	-- Panning end --

	modelScene:SetCameraPosition(self:CalculatePositionByDistanceFromTarget(targetX, targetY, targetZ, zoomDistance, axisAngleX, axisAngleY, axisAngleZ))
end

local function UpdateLight(self)
	if self:ShouldAlignLightToOrbitDelta() then
		local lightYaw = self.lightDeltaYaw + self.interpolatedYaw
		local lightPitch = self.lightDeltaPitch + self.interpolatedPitch
		self:GetOwningScene():SetLightDirection(Vector3D_CalculateNormalFromYawPitch(lightYaw, lightPitch))
	end
end

local deltaModifierForCameraMode = setmetatable({
	[ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_ZOOM] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ZOOM),
	[ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL),
	[ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL),
	[ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL),
	[ORBIT_CAMERA_MOUSE_PAN_VERTICAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL),
}, {__index = function() return 0 end})

local function GetDeltaModifierForCameraMode(self, mode)
	return deltaModifierForCameraMode[mode]
end

local function SetYaw(self, yaw)
	self.yaw = yaw % pi2
end

local function SetPitch(self, pitch)
	self.pitch = pitch % pi2
end

local function SetRoll(self, roll)
	self.roll = roll % pi2
end

local function normalizeRad(angle, defAngle)
	angle = math.fmod((angle or 0) - defAngle, pi2)
	if angle > math.pi then angle = angle - pi2
	elseif angle < -math.pi then angle = angle + pi2 end
	return angle + defAngle
end

local function resetPosition(self)
	self.accX = nil
	self.accY = nil
	self.interpolatedYaw = normalizeRad(self.interpolatedYaw, self.modelSceneCameraInfo.yaw)
	self.interpolatedPitch = normalizeRad(self.interpolatedPitch, self.modelSceneCameraInfo.pitch)
	self.interpolatedRoll = normalizeRad(self.interpolatedRoll, self.modelSceneCameraInfo.roll)
	self:SetYaw(self.modelSceneCameraInfo.yaw)
	self:SetPitch(self.modelSceneCameraInfo.pitch)
	self:SetRoll(self.modelSceneCameraInfo.roll)
	self:SetZoomDistance(self.modelSceneCameraInfo.zoomDistance)
	self.xOffset = 0
	self.yOffset = self.defYOfsset + (mounts.config.mountDescriptionToggle and self.yOffsetDelta or 0)
end

local function updateYOffset(self)
	self.yOffset = self.yOffset + (mounts.config.mountDescriptionToggle and 1 or -1) * self.yOffsetDelta
end


journal:on("SET_ACTIVE_CAMERA", function(self, activeCamera, isGrid)
	activeCamera.setMaxOffsets = setMaxOffsets
	activeCamera.SaveInitialTransform = SaveInitialTransform
	activeCamera.setAcceleration = setAcceleration
	activeCamera.updateAcceleration = updateAcceleration
	activeCamera.HandleMouseMovement = HandleMouseMovement
	activeCamera.OnUpdate = OnUpdate
	activeCamera.UpdateInterpolationTargets = UpdateInterpolationTargets
	activeCamera.UpdateCameraOrientationAndPosition = UpdateCameraOrientationAndPosition
	activeCamera.UpdateLight = UpdateLight
	activeCamera.GetDeltaModifierForCameraMode = GetDeltaModifierForCameraMode
	activeCamera.SetYaw = SetYaw
	activeCamera.SetPitch = SetPitch
	activeCamera.SetRoll = SetRoll

	activeCamera:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, true)

	if isGrid then
		activeCamera.ApplyFromModelSceneCameraInfo = gridApplyFromModelSceneCameraInfo
		return
	end

	activeCamera.ApplyFromModelSceneCameraInfo = ApplyFromModelSceneCameraInfo
	activeCamera.resetPosition = resetPosition
	activeCamera.updateYOffset = updateYOffset

	activeCamera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true)
	activeCamera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true)

	self:off("JOURNAL_RESIZED.ACTIVE_CAMERA"):on("JOURNAL_RESIZED.ACTIVE_CAMERA", function()
		activeCamera:setMaxOffsets()
	end)
end)