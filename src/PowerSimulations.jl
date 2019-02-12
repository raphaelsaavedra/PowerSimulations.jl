module PowerSimulations

#################################################################################
# Exports

#Core Exports
export PowerSimulationsModel
export PowerResults

#Base Modeling Exports
export CustomModel
export EconomicDispatch
export UnitCommitment

#Network Relevant Exports
export StandardPTDFModel
export CopperPlatePowerModel

#Functions
export buildmodel!
export simulatemodel

#################################################################################
# Imports
import JuMP
#using TimeSeries
import PowerSystems
import PowerModels
import InfrastructureModels
import MathOptInterface
import DataFrames
import LinearAlgebra
import LinearAlgebra.BLAS
import AxisArrays
import Dates

#################################################################################
# Type Alias From other Packages
const PM = PowerModels
const IM = InfrastructureModels
const PSY = PowerSystems
const PSI = PowerSimulations
const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

#Type Alias for JuMP containers
const JumpExpressionMatrix = Matrix{<:JuMP.GenericAffExpr}
const JumpAffineExpressionArray = Array{JuMP.GenericAffExpr{Float64,JuMP.VariableRef},2}

#Type Alias for Unions
const fix_resource = Union{PSY.RenewableFix, PSY.HydroFix}


#################################################################################
# Includes

#Abstract Models
include("network_models/networks.jl")
include("service_models/services.jl")


#base
include("base/core_models/canonical_model.jl")
include("base/core_models/abstract_models.jl")
#include("base/core_models/dynamic_model.jl")
include("base/model_constructors.jl")
#include("base/solve_routines.jl")
#include("base/simulation_routines.jl")

#utils
include("utils/device_retreval.jl")

#Device Modeling components
include("device_models/common.jl")
include("device_models/renewable_generation.jl")
include("device_models/thermal_generation.jl")
include("device_models/electric_loads.jl")
include("device_models/branches.jl")
include("device_models/storage.jl")
include("device_models/hydro_generation.jl")
include("service_models/reserves.jl")

#Network related components
include("network_models/copperplate_model.jl")
include("network_models/powermodels_interface.jl")
include("network_models/ptdf_model.jl")

#Device constructors
include("component_constructors/thermalgeneration_constructor.jl")
include("component_constructors/branch_constructor.jl")
include("component_constructors/renewablegeneration_constructor.jl")
include("component_constructors/load_constructor.jl")
include("component_constructors/storage_constructor.jl")
#include("component_constructors/services_constructor.jl")

#Network constructors
include("component_constructors/network_constructor.jl")

#PowerModels
#include("power_models/economic_dispatch.jl")

#Utils


end
