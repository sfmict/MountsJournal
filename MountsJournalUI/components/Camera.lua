local _, ns = ...
local mounts, journal, math = ns.mounts, ns.journal, math
local ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL, ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION, ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, ORBIT_CAMERA_MOUSE_MODE_ZOOM = ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL, ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION, ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, ORBIT_CAMERA_MOUSE_MODE_ZOOM
local GetScaledCursorDelta, IsShiftKeyDown = GetScaledCursorDelta, IsShiftKeyDown
local DeltaLerp, Clamp = DeltaLerp, Clamp
local pi2 = math.pi * 2


-- QUATERNION
local function quaternion_Multiply(aw, ax, ay, az, bw, bx, by, bz)
	return aw*bw - ax*bx - ay*by - az*bz,
	       aw*bx + ax*bw + ay*bz - az*by,
	       aw*by - ax*bz + ay*bw + az*bx,
	       aw*bz + ax*by - ay*bx + az*bw
end

local function quaternion_FromYawPitchRoll(yaw, pitch, roll)
	local cy = math.cos(yaw * .5)
	local sy = math.sin(yaw * .5)
	local cp = math.cos(pitch * .5)
	local sp = math.sin(pitch * .5)
	local cr = math.cos(roll * .5)
	local sr = math.sin(roll * .5)

	local temp_w, temp_x, temp_y, temp_z = quaternion_Multiply(cy, 0, 0, sy, cp, 0, sp, 0)
	return quaternion_Multiply(temp_w, temp_x, temp_y, temp_z, cr, sr, 0, 0)
end

local function quaternion_ToYawPitchRoll(w, x, y, z)
	local fx = 1 - 2*(y*y + z*z)
	local fy = 2*(x*y + w*z)
	local fz = 2*(x*z - w*y)
	local rz = 2*(y*z + w*x)
	local uz = 1 - 2*(x*x + y*y)

	local sinp = -fz
	local pitch = math.abs(sinp) >= 1 and math.pi / 2*(sinp > 0 and 1 or -1) or math.asin(sinp)
	local yaw = math.atan2(fy, fx)
	local roll = math.atan2(rz, uz)

	return yaw, pitch, roll
end

local function quaternion_Normalize(w, x, y, z)
	local l = math.sqrt(w*w + x*x + y*y + z*z)
	if l > 0 then
		return w/l, x/l, y/l, z/l
	end
	return 1, 0, 0, 0
end

local function quaternion_ToAxisVectors(w, x, y, z)
	-- expected to be normalized
	local xx, yy, zz = x*x, y*y, z*z
	local xy, xz, yz = x*y, x*z, y*z
	local wx, wy, wz = w*x, w*y, w*z

	local fx = 1 - 2*(yy + zz)
	local fy = 2 * (xy + wz)
	local fz = 2 * (xz - wy)

	local rx = 2*(xy - wz)
	local ry = 1 - 2*(xx + zz)
	local rz = 2*(yz + wx)

	local ux = fy*rz - fz*ry
	local uy = fz*rx - fx*rz
	local uz = fx*ry - fy*rx

	return fx, fy, fz, rx, ry, rz, ux, uy, uz
end

local function quaternion_Trackball(hy, hp, qw, qx, qy, qz)
	local _,_,_, rx, ry, rz, ux, uy, uz = quaternion_ToAxisVectors(qw, qx, qy, qz)
	local sy, cy = math.sin(hy), math.cos(hy)
	local sp, cp = math.sin(hp), math.cos(hp)
	local dw, dx, dy, dz = quaternion_Multiply(cy, ux*sy, uy*sy, uz*sy, cp, rx*sp, ry*sp, rz*sp)
	local nw, nx, ny, nz = quaternion_Multiply(dw, dx, dy, dz, qw, qx, qy, qz)
	return quaternion_Normalize(nw, nx, ny, nz)
end

local function quaternion_Slerp(aw, ax, ay, az, bw, bx, by, bz, t)
	local dot = aw*bw + ax*bx + ay*by + az*bz
	if dot < 0 then
		bw, bx, by, bz = -bw, -bx, -by, -bz
		dot = -dot
	end

	if dot > .9995 then
		return quaternion_Normalize(
			aw + (bw - aw) * t,
			ax + (bx - ax) * t,
			ay + (by - ay) * t,
			az + (bz - az) * t
		)
	end

	local theta0 = math.acos(dot)
	local theta = theta0 * t
	local sinTheta = math.sin(theta)
	local sinTheta0 = math.sin(theta0)
	local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
	local s1 = sinTheta / sinTheta0

	return quaternion_Normalize(
		aw*s0 + bw*s1,
		ax*s0 + bx*s1,
		ay*s0 + by*s1,
		az*s0 + bz*s1
	)
end


-- ORBIT CAMERA
local function setMaxOffsets(self)
	local w, h = self:GetOwningScene():GetSize()
	local hw, hh = w / 2, h / 2
	local extra = 50
	self.xMaxOffset = hw + extra
	self.yMaxOffset = hh + extra
	self.xOffset = Clamp(self.xOffset, -self.xMaxOffset, self.xMaxOffset)
	self.yOffset = Clamp(self.yOffset, -self.yMaxOffset, self.yMaxOffset)
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
	modelSceneCameraInfo.minZoomDistance = modelSceneCameraInfo.minZoomDistance - 2
	modelSceneCameraInfo.maxZoomDistance = modelSceneCameraInfo.maxZoomDistance + 8

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

	self.qw, self.qx, self.qy, self.qz = quaternion_FromYawPitchRoll(transitionalCameraInfo.yaw, transitionalCameraInfo.pitch, transitionalCameraInfo.roll)

	if self.xOffset == nil then
		self.defYOffset = 20
		self.yOffsetDelta = 40
		self.xOffset = 0
		self.yOffset = self.defYOffset + (mounts.config.mountDescriptionToggle and self.yOffsetDelta or 0)
		self.panningXOffset = 0
		self.panningYOffset = self.yOffset
		self.pendingYawDelta = 0
		self.pendingPitchDelta = 0
		self:setMaxOffsets()
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
	self.accX = nil
	self.accY = nil
end

local function setAcceleration(self, deltaX, deltaY, elapsed)
	self.accX = deltaX / elapsed * mounts.cameraConfig.xInitialAcceleration
	local xMinInit = 400 * mounts.cameraConfig.xInitialAcceleration
	if self.accX > -xMinInit and self.accX < xMinInit then self.accX = nil end

	self.accY = deltaY / elapsed * mounts.cameraConfig.yInitialAcceleration
	local yMinInit = 400 * mounts.cameraConfig.yInitialAcceleration
	if self.accY > -yMinInit and self.accY < yMinInit then self.accY = nil end
end

local function getDeltaAcceleration(curAcc, elapsed, kAcc, kMinSpeed)
	local decay = math.exp(kAcc * elapsed)
	local delta = curAcc * (decay - 1) / kAcc
	local newAcc = curAcc * decay
	local absAcc = math.abs(newAcc)
	local minSpeed = 50 * kMinSpeed

	if absAcc < minSpeed then
		newAcc = minSpeed * (curAcc < 0 and -1 or 1)
		return newAcc * elapsed, newAcc
	end

	if absAcc < 5 then return end
	return delta, newAcc
end

local function updateAcceleration(self, elapsed)
	if not mounts.cameraConfig.xAccelerationEnabled then self.accX = nil end
	if not mounts.cameraConfig.yAccelerationEnabled then self.accY = nil end

	if self.accX then
		local deltaX, accX = getDeltaAcceleration(self.accX, elapsed, mounts.cameraConfig.xAcceleration, mounts.cameraConfig.xMinSpeed)
		self.accX = accX
		if deltaX then
			self:HandleMouseMovement(self.buttonModes.leftX, deltaX)
		end
	end

	if self.accY then
		local deltaY, accY = getDeltaAcceleration(self.accY, elapsed, mounts.cameraConfig.yAcceleration, mounts.cameraConfig.yMinSpeed)
		self.accY = accY
		if deltaY then
			self:HandleMouseMovement(self.buttonModes.leftY, deltaY)
		end
	end
end

local function HandleMouseMovement(self, mode, delta, snapToValue)
	delta = delta * self:GetDeltaModifierForCameraMode(mode)

	if mode == ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION then
		self.pendingYawDelta = delta

	elseif mode == ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION then
		self.pendingPitchDelta = delta

	elseif mode == ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL then
		self.xOffset = Clamp(self.xOffset + delta, -self.xMaxOffset, self.xMaxOffset)
		if snapToValue then self.panningXOffset = nil end

	elseif mode == ORBIT_CAMERA_MOUSE_PAN_VERTICAL then
		self.yOffset = Clamp(self.yOffset + delta, -self.yMaxOffset, self.yMaxOffset)
		if snapToValue then self.panningYOffset = nil end

	elseif mode == ORBIT_CAMERA_MOUSE_MODE_ZOOM then
		self:ZoomByPercent(delta)
		if snapToValue then self:SnapToTargetInterpolationZoom() end
	end
end

local function OnMouseWheel(self, delta)
	self:HandleMouseMovement(self.buttonModes.wheel, delta, not self.buttonModes.wheelInterpolate)
end

local function OnUpdate(self, elapsed)
	if self:IsLeftMouseButtonDown() then
		local deltaX, deltaY = GetScaledCursorDelta()
		self:setAcceleration(deltaX, deltaY, elapsed)
		self:HandleMouseMovement(self.buttonModes.leftX, deltaX)
		self:HandleMouseMovement(self.buttonModes.leftY, deltaY)
	elseif self.accX or self.accY then
		self:updateAcceleration(elapsed)
	end

	if self:IsRightMouseButtonDown() then
		local deltaX, deltaY = GetScaledCursorDelta()
		self:HandleMouseMovement(self.buttonModes.rightX, deltaX, not self.buttonModes.rightXinterpolate)
		self:HandleMouseMovement(self.buttonModes.rightY, -deltaY, not self.buttonModes.rightYinterpolate)
	end

	local shiftDown = IsShiftKeyDown()
	-- interpolation starts when shift is released
	if not shiftDown and self.wasShiftDown then
		local yaw, pitch = quaternion_ToYawPitchRoll(self.qw, self.qx, self.qy, self.qz)
		self:SetYaw(yaw)
		self:SetPitch(pitch)

		local speed = 0
		if self.pendingYawDelta ~= 0 or self.pendingPitchDelta ~= 0 then
			speed = math.sqrt(self.pendingYawDelta^2 + self.pendingPitchDelta^2) / elapsed
		end

		self:startInterpolatedQ(speed)
	end
	self.wasShiftDown = shiftDown

	-- quaternion rotation
	if self.pendingYawDelta ~= 0 or self.pendingPitchDelta ~= 0 then
		if shiftDown then
			self.interpolatedQ = nil
			local k = -.7
			self.qw, self.qx, self.qy, self.qz = quaternion_Trackball(
				self.pendingYawDelta * k,
				self.pendingPitchDelta * k,
				self.qw, self.qx, self.qy, self.qz
			)
		else
			if self.interpolatedQ ~= 2 then self.interpolatedQ = nil end
			self:SetYaw(self:GetYaw() - self.pendingYawDelta)
			self:SetPitch(self:GetPitch() - self.pendingPitchDelta)

			if self.interpolatedQ == nil then
				self.qw, self.qx, self.qy, self.qz = quaternion_FromYawPitchRoll(self:GetYaw(), self:GetPitch(), self:GetRoll())
			end
		end
		self.pendingYawDelta, self.pendingPitchDelta = 0, 0
	end

	self:UpdateInterpolationTargets(elapsed)
	self:SynchronizeCamera()
end

local function startInterpolatedQ(self, angularSpeed)
	self.interpCounter = 50 + (angularSpeed or 0) * 10
	if self.interpolatedQ ~= 2 then
		self.interpolatedQ = angularSpeed and 2 or 1
	end
end

local function InterpolateDimension(lastValue, targetValue, amount, elapsed)
	return lastValue and DeltaLerp(lastValue, targetValue, amount, elapsed) or targetValue
end

local function UpdateInterpolationTargets(self, elapsed)
	local targetX, targetY, targetZ = self:GetDerivedTarget()
	local zoomDistance = self:GetDerivedZoomDistance()
	local amount = .15

	self.interpolatedZoomDistance = InterpolateDimension(self.interpolatedZoomDistance, zoomDistance, amount, elapsed)

	self.interpolatedTargetX = InterpolateDimension(self.interpolatedTargetX, targetX, amount, elapsed)
	self.interpolatedTargetY = InterpolateDimension(self.interpolatedTargetY, targetY, amount, elapsed)
	self.interpolatedTargetZ = InterpolateDimension(self.interpolatedTargetZ, targetZ, amount, elapsed)

	self.panningXOffset = InterpolateDimension(self.panningXOffset, self.xOffset, amount, elapsed)
	self.panningYOffset = InterpolateDimension(self.panningYOffset, self.yOffset, amount, elapsed)

	if self.interpolatedQ then
		local tw, tx, ty, tz = quaternion_FromYawPitchRoll(self:GetYaw(), self:GetPitch(), self:GetRoll())

		self.interpCounter = self.interpCounter + 120 * elapsed
		local t = Clamp(elapsed * amount * self.interpCounter, 0, 1)
		self.qw, self.qx, self.qy, self.qz = quaternion_Slerp(self.qw, self.qx, self.qy, self.qz, tw, tx, ty, tz, t)

		local dot = math.abs(self.qw*tw + self.qx*tx + self.qy*ty + self.qz*tz)
		local angle = 2 * math.acos(dot > 1 and 1 or dot)

		-- .00087 = .5°
		if self.interpolatedQ == 2 and angle < .0087 or angle == 0 then
			self.qw, self.qx, self.qy, self.qz = tw, tx, ty, tz
			self.interpolatedQ = nil
		end
	end
end

local function UpdateCameraOrientationAndPosition(self)
	local modelScene = self:GetOwningScene()
	local fx, fy, fz, rx, ry, rz, ux, uy, uz = quaternion_ToAxisVectors(self.qw, self.qx, self.qy, self.qz)
	modelScene:SetCameraOrientationByAxisVectors(fx, fy, fz, rx, ry, rz, ux, uy, uz)

	local targetX, targetY, targetZ = self:GetInterpolatedTarget()
	local zoomDistance = self:GetInterpolatedZoomDistance()
	local width, height = modelScene:GetSize()

	local zoomFactor = 1
	if zoomDistance > 1 then
		zoomFactor = zoomDistance - 1 / (zoomDistance * zoomDistance * zoomDistance)
		if zoomFactor < 1 then zoomFactor = 1 end
	end
	zoomFactor = zoomFactor / math.sqrt(width * width + height * height)

	local xOffset = self.panningXOffset * zoomFactor
	local yOffset = self.panningYOffset * zoomFactor

	local camPosX = targetX + xOffset * rx + yOffset * ux - fx * zoomDistance
	local camPosY = targetY + xOffset * ry + yOffset * uy - fy * zoomDistance
	local camPosZ = targetZ + xOffset * rz + yOffset * uz - fz * zoomDistance
	modelScene:SetCameraPosition(camPosX, camPosY, camPosZ)
end

local function UpdateLight(self)
	if self:ShouldAlignLightToOrbitDelta() then
		self:GetOwningScene():SetLightDirection(self:GetForwardVector())
	end
end

local deltaModifierForCameraMode = setmetatable({
	[ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION),
	[ORBIT_CAMERA_MOUSE_MODE_ZOOM] = .075,
	[ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL),
	[ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL),
	[ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL),
	[ORBIT_CAMERA_MOUSE_PAN_VERTICAL] = OrbitCameraMixin:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL),
}, {__index = function() return 1 end})

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

-- local function normalizeRad(angle, defAngle)
-- 	angle = math.fmod((angle or 0) - defAngle, pi2)
-- 	if angle > math.pi then angle = angle - pi2
-- 	elseif angle < -math.pi then angle = angle + pi2 end
-- 	return angle + defAngle
-- end

local function resetPosition(self)
	self.accX = nil
	self.accY = nil
	self.pendingYawDelta = 0
	self.pendingPitchDelta = 0
	-- self.interpolatedYaw = normalizeRad(self.interpolatedYaw, self.modelSceneCameraInfo.yaw)
	-- self.interpolatedPitch = normalizeRad(self.interpolatedPitch, self.modelSceneCameraInfo.pitch)
	-- self.interpolatedRoll = normalizeRad(self.interpolatedRoll, self.modelSceneCameraInfo.roll)
	self:SetYaw(self.modelSceneCameraInfo.yaw)
	self:SetPitch(self.modelSceneCameraInfo.pitch)
	self:SetRoll(self.modelSceneCameraInfo.roll)
	self:SetZoomDistance(self.modelSceneCameraInfo.zoomDistance)
	self:startInterpolatedQ()
	self.xOffset = 0
	self.yOffset = self.defYOffset + (mounts.config.mountDescriptionToggle and self.yOffsetDelta or 0)
end

local function updateYOffset(self)
	self.yOffset = self.yOffset + (mounts.config.mountDescriptionToggle and 1 or -1) * self.yOffsetDelta
end


journal:on("SET_ACTIVE_CAMERA", function(self, activeCamera, isGrid)
	activeCamera.setMaxOffsets = setMaxOffsets
	activeCamera.setAcceleration = setAcceleration
	activeCamera.updateAcceleration = updateAcceleration
	activeCamera.HandleMouseMovement = HandleMouseMovement
	activeCamera.OnUpdate = OnUpdate
	activeCamera.startInterpolatedQ = startInterpolatedQ
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
	activeCamera.OnMouseWheel = OnMouseWheel
	activeCamera.resetPosition = resetPosition
	activeCamera.updateYOffset = updateYOffset

	activeCamera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true)
	activeCamera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true)

	self:off("JOURNAL_RESIZED.ACTIVE_CAMERA"):on("JOURNAL_RESIZED.ACTIVE_CAMERA", function()
		activeCamera:setMaxOffsets()
	end)
end)