local mounts, journal = MountsJournal, MountsJournalFrame


journal:on("SET_ACTIVE_CAMERA", function(self, activeCamera)
	local GetScaledCursorDelta = GetScaledCursorDelta
	local GetScaledCursorPosition = GetScaledCursorPosition
	local mountDisplay = self.MountJournal.MountDisplay

	activeCamera.panningXOffset = 0
	activeCamera.panningYOffset = 0

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
		if modificationType ~= CAMERA_MODIFICATION_TYPE_MAINTAIN then
			self.xOffset = 0
			self.yOffset = mounts.config.mountDescriptionToggle and 40 or 0
		end

		local pi2 = math.pi * 2
		activeCamera.yaw = math.fmod(activeCamera.yaw, pi2)
		activeCamera.interpolatedYaw = math.fmod(activeCamera.interpolatedYaw or 0, pi2)
		activeCamera.pitch = math.fmod(activeCamera.pitch, pi2)
		activeCamera.interpolatedPitch = math.fmod(activeCamera.interpolatedPitch or 0, pi2)

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

		if transitionType == CAMERA_TRANSITION_TYPE_IMMEDIATE then
			self:SnapAllInterpolatedValues()
		end
		self:UpdateCameraOrientationAndPosition()

		self:SaveInitialTransform(transitionalCameraInfo)
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
			if deltaX > 0 and x > mountDisplay:GetLeft() - 70
			or deltaX < 0 and x < mountDisplay:GetRight() + 70 then
				self:HandleMouseMovement(self.buttonModes.rightX, deltaX * self:GetDeltaModifierForCameraMode(self.buttonModes.rightX), not self.buttonModes.rightXinterpolate)
			end
			if deltaY > 0 and y > mountDisplay:GetBottom() - 70
			or deltaY < 0 and y < mountDisplay:GetTop() + 70 then
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

	activeCamera:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, true)
	activeCamera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true)
	activeCamera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true)

	activeCamera.deltaModifierForCameraMode = {
		[ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION),
		[ORBIT_CAMERA_MOUSE_MODE_ZOOM] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ZOOM),
		[ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL),
		[ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL),
		[ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL),
		[ORBIT_CAMERA_MOUSE_PAN_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL),
	}
	setmetatable(activeCamera.deltaModifierForCameraMode, {__index = function()
		return 0
	end})
	function activeCamera:GetDeltaModifierForCameraMode(mode)
		return self.deltaModifierForCameraMode[mode]
	end
end)