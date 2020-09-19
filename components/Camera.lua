local mounts, journal = MountsJournal, MountsJournalFrame


journal:on("SET_ACTIVE_CAMERA", function(self, activeCamera)
	local ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL = ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, ORBIT_CAMERA_MOUSE_PAN_VERTICAL
	local GetScaledCursorDelta, GetScaledCursorPosition = GetScaledCursorDelta, GetScaledCursorPosition
	local DeltaLerp, Vector3D_CalculateNormalFromYawPitch, Vector3D_ScaleBy, Vector3D_Add = DeltaLerp, Vector3D_CalculateNormalFromYawPitch, Vector3D_ScaleBy, Vector3D_Add

	function activeCamera:SaveInitialTransform()
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

	function activeCamera:ApplyFromModelSceneCameraInfo(modelSceneCameraInfo, transitionType, modificationType)
		modelSceneCameraInfo.target.z = 1
		modelSceneCameraInfo.maxZoomDistance = 24

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
			self.xOffset = 0
			self.yOffset = mounts.config.mountDescriptionToggle and 40 or 0
			self.panningXOffset = 0
			self.panningYOffset = self.yOffset
			self:SaveInitialTransform()
		end

		if transitionType == CAMERA_TRANSITION_TYPE_IMMEDIATE then
			self:SnapAllInterpolatedValues()
		end
		self:UpdateCameraOrientationAndPosition()
	end

	local HandleMouseMovement = activeCamera.HandleMouseMovement
	function activeCamera:HandleMouseMovement(mode, delta, snapToValue)
		if mode == ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL then
			self.xOffset = self.xOffset + delta

			if self.xOffset > 250 then self.xOffset = 250
			elseif self.xOffset < -250 then self.xOffset = -250 end

			if snapToValue then
				self.panningXOffset = nil
			end
		elseif mode == ORBIT_CAMERA_MOUSE_PAN_VERTICAL then
			self.yOffset = self.yOffset + delta

			if self.yOffset > 280 then self.yOffset = 280
			elseif self.yOffset < -280 then self.yOffset = -280 end

			if snapToValue then
				self.panningYOffset = nil
			end
		else
			HandleMouseMovement(self, mode, delta, snapToValue)
		end
	end

	function activeCamera:OnUpdate(elapsed)
		if self:IsLeftMouseButtonDown() then
			local deltaX, deltaY = GetScaledCursorDelta()
			self:HandleMouseMovement(self.buttonModes.leftX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.leftX), not self.buttonModes.leftXinterpolate)
			self:HandleMouseMovement(self.buttonModes.leftY, deltaY * self:GetDeltaModifierForCameraMode(self.buttonModes.leftY), not self.buttonModes.leftYinterpolate)
		end

		if self:IsRightMouseButtonDown() then
			local deltaX, deltaY = GetScaledCursorDelta()
			local x, y = GetScaledCursorPosition()
			local modelScene = self:GetOwningScene()
			if deltaX > 0 and x > modelScene:GetLeft() - 65
			or deltaX < 0 and x < modelScene:GetRight() + 65 then
				self:HandleMouseMovement(self.buttonModes.rightX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.rightX), not self.buttonModes.rightXinterpolate)
			end
			if deltaY > 0 and y > modelScene:GetBottom() - 60
			or deltaY < 0 and y < modelScene:GetTop() + 60 then
				self:HandleMouseMovement(self.buttonModes.rightY, -deltaY * self:GetDeltaModifierForCameraMode(self.buttonModes.rightY), not self.buttonModes.rightYinterpolate)
			end
		end

		self:UpdateInterpolationTargets(elapsed)
		self:SynchronizeCamera()
	end

	local function InterpolateDimension(lastValue, targetValue, amount, elapsed)
		return lastValue and DeltaLerp(lastValue, targetValue, amount, elapsed) or targetValue
	end

	hooksecurefunc(activeCamera, "UpdateInterpolationTargets", function(self, elapsed)
		self.panningXOffset = InterpolateDimension(self.panningXOffset, self.xOffset, .15, elapsed)
		self.panningYOffset = InterpolateDimension(self.panningYOffset, self.yOffset, .15, elapsed)
	end)

	function activeCamera:UpdateCameraOrientationAndPosition()
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

	function activeCamera:UpdateLight()
		if self:ShouldAlignLightToOrbitDelta() then
			local lightYaw = self.lightDeltaYaw + self.interpolatedYaw
			local lightPitch = self.lightDeltaPitch + self.interpolatedPitch
			self:GetOwningScene():SetLightDirection(Vector3D_CalculateNormalFromYawPitch(lightYaw, lightPitch))
		end
	end

	activeCamera:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, true)
	activeCamera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true)
	activeCamera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true)

	activeCamera.deltaModifierForCameraMode = setmetatable({
		[ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_ZOOM] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ZOOM),
		[ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL),
		[ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL),
		[ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL),
		[ORBIT_CAMERA_MOUSE_PAN_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL),
	}, {__index = function() return 0 end})

	function activeCamera:GetDeltaModifierForCameraMode(mode)
		return self.deltaModifierForCameraMode[mode]
	end

	function activeCamera:resetPosition()
		local pi2 = math.pi * 2
		self.interpolatedYaw = math.fmod(self.interpolatedYaw or 0, pi2)
		self.interpolatedPitch = math.fmod(self.interpolatedPitch or 0, pi2)

		self:SetYaw(self.modelSceneCameraInfo.yaw)
		self:SetPitch(self.modelSceneCameraInfo.pitch)
		self:SetRoll(self.modelSceneCameraInfo.roll)
		self:SetZoomDistance(self.modelSceneCameraInfo.zoomDistance)
		self.xOffset = 0
		self.yOffset = mounts.config.mountDescriptionToggle and 40 or 0
	end
end)