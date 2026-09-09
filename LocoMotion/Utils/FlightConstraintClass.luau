--!strict
local FlightConstraintClass = {}
FlightConstraintClass.__index = FlightConstraintClass

type FlightConstraintType = {
	_lv: LinearVelocity,
	_gyro: AngularVelocity,
}

function FlightConstraintClass.new(hrp: BasePart): FlightConstraint
	local self = setmetatable({} :: FlightConstraint, FlightConstraintClass)

	local attachment: any = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)

	attachment.Name = "RootAttachment"

	local lv = Instance.new("LinearVelocity")
	lv.Name = "FlightVelocity"
	lv.Attachment0 = attachment
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = 1000000
	lv.VectorVelocity = Vector3.zero
	lv.Parent = hrp

	local gyro = Instance.new("AngularVelocity")
	gyro.Name = "FlightGyro"
	gyro.Attachment0 = attachment
	gyro.MaxTorque = 1000000
	gyro.AngularVelocity = Vector3.zero
	gyro.Parent = hrp

	self._lv = lv
	self._gyro = gyro

	return self
end

function FlightConstraintClass.SetVelocity(self: FlightConstraint, velocity: Vector3)
	self._lv.VectorVelocity = velocity
end

function FlightConstraintClass.Destroy(self: FlightConstraint)
	self._lv:Destroy()
	self._gyro:Destroy()
end

export type FlightConstraint = typeof(FlightConstraintClass) & FlightConstraintType

return FlightConstraintClass
