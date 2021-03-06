abstract type AbstractHydroFormulation <: AbstractDeviceFormulation end
abstract type AbstractHydroDispatchFormulation <: AbstractHydroFormulation end
abstract type AbstractHydroUnitCommitment <: AbstractHydroFormulation end
abstract type AbstractHydroReservoirFormulation <: AbstractHydroDispatchFormulation end
struct HydroDispatchRunOfRiver <: AbstractHydroDispatchFormulation end
struct HydroDispatchReservoirBudget <: AbstractHydroReservoirFormulation end
struct HydroDispatchReservoirStorage <: AbstractHydroReservoirFormulation end
struct HydroCommitmentRunOfRiver <: AbstractHydroUnitCommitment end
struct HydroCommitmentReservoirBudget <: AbstractHydroUnitCommitment end
struct HydroCommitmentReservoirStorage <: AbstractHydroUnitCommitment end

########################### Hydro generation variables #################################

"""
This function add the variables for active power to the model
"""
function AddVariableSpec(
    ::Type{T},
    ::Type{U},
    ::PSIContainer,
) where {T <: ActivePowerVariable, U <: PSY.HydroGen}
    return AddVariableSpec(;
        variable_name = make_variable_name(T, U),
        binary = false,
        expression_name = :nodal_balance_active,
        initial_value_func = x -> PSY.get_active_power(x),
        lb_value_func = x -> PSY.get_active_power_limits(x).min,
        ub_value_func = x -> PSY.get_active_power_limits(x).max,
    )
end

"""
This function add the variables for reactive power to the model
"""
function AddVariableSpec(
    ::Type{T},
    ::Type{U},
    ::PSIContainer,
) where {T <: ReactivePowerVariable, U <: PSY.HydroGen}
    return AddVariableSpec(;
        variable_name = make_variable_name(T, U),
        binary = false,
        expression_name = :nodal_balance_reactive,
        initial_value_func = x -> PSY.get_reactive_power(x),
        lb_value_func = x -> PSY.get_reactive_power_limits(x).min,
        ub_value_func = x -> PSY.get_reactive_power_limits(x).max,
    )
end

"""
This function add the variables for energy storage to the model
"""
function AddVariableSpec(
    ::Type{T},
    ::Type{U},
    ::PSIContainer,
) where {T <: EnergyVariable, U <: PSY.HydroGen}
    return AddVariableSpec(;
        variable_name = make_variable_name(T, U),
        binary = false,
        initial_value_func = x -> PSY.get_initial_storage(x),
        lb_value_func = x -> 0.0,
        ub_value_func = x -> PSY.get_storage_capacity(x),
    )
end

"""
This function add the variables for power generation commitment to the model
"""
function AddVariableSpec(
    ::Type{T},
    ::Type{U},
    psi_container::PSIContainer,
) where {T <: OnVariable, U <: PSY.HydroGen}
    return AddVariableSpec(; variable_name = make_variable_name(T, U), binary = true)
end

"""
This function add the spillage variable for storage models
"""
function AddVariableSpec(
    ::Type{T},
    ::Type{U},
    ::PSIContainer,
) where {T <: SpillageVariable, U <: PSY.HydroGen}
    return AddVariableSpec(;
        variable_name = make_variable_name(T, U),
        binary = false,
        lb_value_func = x -> 0.0,
    )
end

"""
This function define the range constraint specs for the
reactive power for dispatch formulations.
"""
function DeviceRangeConstraintSpec(
    ::Type{<:RangeConstraint},
    ::Type{ReactivePowerVariable},
    ::Type{T},
    ::Type{<:AbstractHydroDispatchFormulation},
    ::Type{<:PM.AbstractPowerModel},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
    use_parameters::Bool,
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    return DeviceRangeConstraintSpec(;
        range_constraint_spec = RangeConstraintSpec(;
            constraint_name = make_constraint_name(
                RangeConstraint,
                ReactivePowerVariable,
                T,
            ),
            variable_name = make_variable_name(ReactivePowerVariable, T),
            limits_func = x -> PSY.get_reactive_power_limits(x),
            constraint_func = device_range!,
            constraint_struct = DeviceRangeConstraintInfo,
        ),
    )
end

"""
This function define the range constraint specs for the
active power for dispatch Run of River formulations.
"""
function DeviceRangeConstraintSpec(
    ::Type{<:RangeConstraint},
    ::Type{ActivePowerVariable},
    ::Type{T},
    ::Type{<:AbstractHydroDispatchFormulation},
    ::Type{<:PM.AbstractPowerModel},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
    use_parameters::Bool,
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    if !use_parameters && !use_forecasts
        return DeviceRangeConstraintSpec(;
            range_constraint_spec = RangeConstraintSpec(;
                constraint_name = make_constraint_name(
                    RangeConstraint,
                    ActivePowerVariable,
                    T,
                ),
                variable_name = make_variable_name(ActivePowerVariable, T),
                limits_func = x -> (min = 0.0, max = PSY.get_active_power(x)),
                constraint_func = device_range!,
                constraint_struct = DeviceRangeConstraintInfo,
            ),
        )
    end

    return DeviceRangeConstraintSpec(;
        timeseries_range_constraint_spec = TimeSeriesConstraintSpec(
            constraint_name = make_constraint_name(RangeConstraint, ActivePowerVariable, T),
            variable_name = make_variable_name(ActivePowerVariable, T),
            parameter_name = use_parameters ? ACTIVE_POWER : nothing,
            forecast_label = "get_max_active_power",
            multiplier_func = x -> PSY.get_max_active_power(x),
            constraint_func = use_parameters ? device_timeseries_param_ub! :
                              device_timeseries_ub!,
        ),
    )
end

"""
This function define the range constraint specs for the
active power for dispatch Reservoir formulations.
"""
function DeviceRangeConstraintSpec(
    ::Type{<:RangeConstraint},
    ::Type{ActivePowerVariable},
    ::Type{T},
    ::Type{<:AbstractHydroReservoirFormulation},
    ::Type{<:PM.AbstractPowerModel},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
    use_parameters::Bool,
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    return DeviceRangeConstraintSpec(;
        range_constraint_spec = RangeConstraintSpec(;
            constraint_name = make_constraint_name(RangeConstraint, ActivePowerVariable, T),
            variable_name = make_variable_name(ActivePowerVariable, T),
            limits_func = x -> PSY.get_active_power_limits(x),
            constraint_func = device_range!,
            constraint_struct = DeviceRangeConstraintInfo,
        ),
    )
end

"""
This function define the range constraint specs for the
active power for commitment formulations (semi continuous).
"""
function DeviceRangeConstraintSpec(
    ::Type{<:RangeConstraint},
    ::Type{ActivePowerVariable},
    ::Type{T},
    ::Type{<:AbstractHydroUnitCommitment},
    ::Type{<:PM.AbstractPowerModel},
    feedforward::Nothing,
    use_parameters::Bool,
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    return DeviceRangeConstraintSpec(;
        range_constraint_spec = RangeConstraintSpec(;
            constraint_name = make_constraint_name(RangeConstraint, ActivePowerVariable, T),
            variable_name = make_variable_name(ActivePowerVariable, T),
            bin_variable_names = [make_variable_name(OnVariable, T)],
            limits_func = x -> PSY.get_active_power_limits(x),
            constraint_func = device_semicontinuousrange!,
            constraint_struct = DeviceRangeConstraintInfo,
        ),
    )
end

"""
This function define the range constraint specs for the
reactive power for commitment formulations (semi continuous).
"""
function DeviceRangeConstraintSpec(
    ::Type{<:RangeConstraint},
    ::Type{ReactivePowerVariable},
    ::Type{T},
    ::Type{<:AbstractHydroUnitCommitment},
    ::Type{<:PM.AbstractPowerModel},
    feedforward::Nothing,
    use_parameters::Bool,
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    return DeviceRangeConstraintSpec(;
        range_constraint_spec = RangeConstraintSpec(;
            constraint_name = make_constraint_name(
                RangeConstraint,
                ReactivePowerVariable,
                T,
            ),
            variable_name = make_variable_name(ReactivePowerVariable, T),
            bin_variable_names = [make_variable_name(OnVariable, T)],
            limits_func = x -> PSY.get_active_power_limits(x),
            constraint_func = device_semicontinuousrange!,
            constraint_struct = DeviceRangeConstraintInfo,
        ),
    )
end

######################## RoR constraints ############################

"""
This function define the range constraint specs for the
reactive power for Commitment Run of River formulation.
    `` P <= multiplier * P_max ``
"""
function commit_hydro_active_power_ub!(
    psi_container::PSIContainer,
    devices,
    model::DeviceModel{V, W},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
) where {V <: PSY.HydroGen, W <: AbstractHydroUnitCommitment}
    use_parameters = model_has_parameters(psi_container)
    use_forecasts = model_uses_forecasts(psi_container)
    if use_parameters || use_forecasts
        spec = DeviceRangeConstraintSpec(;
            timeseries_range_constraint_spec = TimeSeriesConstraintSpec(
                constraint_name = make_constraint_name(
                    RangeConstraint,
                    ActivePowerVariable,
                    V,
                ),
                variable_name = make_variable_name(ActivePowerVariable, V),
                parameter_name = use_parameters ? ACTIVE_POWER : nothing,
                forecast_label = "get_max_active_power",
                multiplier_func = x -> PSY.get_max_active_power(x),
                constraint_func = use_parameters ? device_timeseries_param_ub! :
                                      device_timeseries_ub!,
            ),
        )
        device_range_constraints!(psi_container, devices, model, feedforward, spec)
    end
end

######################## Energy balance constraints ############################

"""
This function define the constraints for the water level (or state of charge)
for the Hydro Reservoir.
"""
function energy_balance_constraint!(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    model::DeviceModel{H, S},
    system_formulation::Type{<:PM.AbstractPowerModel},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
) where {
    H <: PSY.HydroEnergyReservoir,
    S <: Union{HydroDispatchReservoirStorage, HydroCommitmentReservoirStorage},
}
    key = ICKey(EnergyLevel, H)
    parameters = model_has_parameters(psi_container)
    use_forecast_data = model_uses_forecasts(psi_container)

    if !has_initial_conditions(psi_container.initial_conditions, key)
        throw(IS.DataFormatError("Initial Conditions for $(H) Energy Constraints not in the model"))
    end

    forecast_label = "get_inflow"
    constraint_infos = Vector{DeviceTimeSeriesConstraintInfo}(undef, length(devices))
    for (ix, d) in enumerate(devices)
        ts_vector = get_time_series(psi_container, d, forecast_label)
        constraint_info =
            DeviceTimeSeriesConstraintInfo(d, x -> PSY.get_inflow(x), ts_vector)
        add_device_services!(constraint_info.range, d, model)
        constraint_infos[ix] = constraint_info
    end

    if parameters
        energy_balance_hydro_param!(
            psi_container,
            get_initial_conditions(psi_container, key),
            constraint_infos,
            make_constraint_name(ENERGY_CAPACITY, H),
            (
                make_variable_name(SPILLAGE, H),
                make_variable_name(ACTIVE_POWER, H),
                make_variable_name(ENERGY, H),
            ),
            UpdateRef{H}(INFLOW, forecast_label),
        )
    else
        energy_balance_hydro!(
            psi_container,
            get_initial_conditions(psi_container, key),
            constraint_infos,
            make_constraint_name(ENERGY_CAPACITY, H),
            (
                make_variable_name(SPILLAGE, H),
                make_variable_name(ACTIVE_POWER, H),
                make_variable_name(ENERGY, H),
            ),
        )
    end
    return
end

########################## Make initial Conditions for a Model #############################
function initial_conditions!(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    device_formulation::Type{<:AbstractHydroUnitCommitment},
) where {H <: PSY.HydroGen}
    status_init(psi_container, devices)
    output_init(psi_container, devices)
    duration_init(psi_container, devices)

    return
end

function initial_conditions!(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    device_formulation::Type{D},
) where {H <: PSY.HydroGen, D <: AbstractHydroDispatchFormulation}
    output_init.initial_conditions_container(psi_container, devices)

    return
end

########################## Addition to the nodal balances #################################

function NodalExpressionSpec(
    ::Type{T},
    ::Type{<:PM.AbstractActivePowerModel},
    use_forecasts::Bool,
) where {T <: PSY.HydroGen}
    return NodalExpressionSpec(
        "get_max_active_power",
        ACTIVE_POWER,
        use_forecasts ? x -> PSY.get_max_active_power(x) : x -> PSY.get_active_power(x),
        1.0,
        T,
    )
end

##################################### Hydro generation cost ############################
function cost_function(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{PSY.HydroEnergyReservoir},
    device_formulation::Type{D},
    system_formulation::Type{<:PM.AbstractPowerModel},
) where {D <: AbstractHydroFormulation}
    add_to_cost!(
        psi_container,
        devices,
        make_variable_name(ACTIVE_POWER, PSY.HydroEnergyReservoir),
        :fixed,
        -1.0,
    )

    return
end

function cost_function(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    device_formulation::Type{D},
    system_formulation::Type{<:PM.AbstractPowerModel},
) where {D <: AbstractHydroFormulation, H <: PSY.HydroGen}

    return
end

##################################### Water/Energy Budget Constraint ############################
function energy_budget_constraints!(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    model::DeviceModel{H, <:AbstractHydroFormulation},
    system_formulation::Type{<:PM.AbstractPowerModel},
    feedforward::IntegralLimitFF,
) where {H <: PSY.HydroGen}
    return
end

"""
This function define the budget constraint for the
active power budget formulation.

`` sum(P[t]) <= Budget ``
"""
function energy_budget_constraints!(
    psi_container::PSIContainer,
    devices::IS.FlattenIteratorWrapper{H},
    model::DeviceModel{H, <:AbstractHydroFormulation},
    system_formulation::Type{<:PM.AbstractPowerModel},
    feedforward::Union{Nothing, AbstractAffectFeedForward},
) where {H <: PSY.HydroGen}

    forecast_label = "get_hydro_budget"
    constraint_data = Vector{DeviceTimeSeriesConstraintInfo}(undef, length(devices))
    for (ix, d) in enumerate(devices)
        ts_vector = get_time_series(psi_container, d, forecast_label)
        constraint_d =
            DeviceTimeSeriesConstraintInfo(d, x -> PSY.get_storage_capacity(x), ts_vector)
        constraint_data[ix] = constraint_d
    end

    if model_has_parameters(psi_container)
        device_energy_budget_param_ub(
            psi_container,
            constraint_data,
            make_constraint_name(ENERGY_BUDGET, H),
            UpdateRef{H}(ENERGY_BUDGET, forecast_label),
            make_variable_name(ACTIVE_POWER, H),
        )
    else
        device_energy_budget_ub(
            psi_container,
            constraint_data,
            make_constraint_name(ENERGY_BUDGET),
            make_variable_name(ACTIVE_POWER, H),
        )
    end
end

"""
This function define the budget constraint (using params)
for the active power budget formulation.
"""
function device_energy_budget_param_ub(
    psi_container::PSIContainer,
    energy_budget_data::Vector{DeviceTimeSeriesConstraintInfo},
    cons_name::Symbol,
    param_reference::UpdateRef,
    var_name::Symbol,
)
    time_steps = model_time_steps(psi_container)
    resolution = model_resolution(psi_container)
    inv_dt = 1.0 / (Dates.value(Dates.Second(resolution)) / SECONDS_IN_HOUR)
    variable = get_variable(psi_container, var_name)
    set_name = [get_component_name(r) for r in energy_budget_data]
    constraint = add_cons_container!(psi_container, cons_name, set_name)
    container = add_param_container!(psi_container, param_reference, set_name, 1)
    multiplier = get_multiplier_array(container)
    param = get_parameter_array(container)
    for constraint_info in energy_budget_data
        name = get_component_name(constraint_info)
        multiplier[name, 1] = constraint_info.multiplier * inv_dt
        param[name, 1] =
            PJ.add_parameter(psi_container.JuMPmodel, sum(constraint_info.timeseries))
        constraint[name] = JuMP.@constraint(
            psi_container.JuMPmodel,
            sum([variable[name, t] for t in time_steps]) <= multiplier[name, 1] * param[name, 1]
        )
    end

    return
end

"""
This function define the budget constraint
for the active power budget formulation.
"""
function device_energy_budget_ub(
    psi_container::PSIContainer,
    energy_budget_constraints::Vector{DeviceTimeSeriesConstraintInfo},
    cons_name::Symbol,
    var_name::Symbol,
)
    time_steps = model_time_steps(psi_container)
    variable = get_variable(psi_container, var_name)
    names = [get_component_name(x) for x in energy_budget_constraints]
    constraint = add_cons_container!(psi_container, cons_name, names)

    for constraint_info in energy_budget_constraints
        name = get_component_name(constraint_info)
        resolution = model_resolution(psi_container)
        inv_dt = 1.0 / (Dates.value(Dates.Second(resolution)) / SECONDS_IN_HOUR)
        forecast = constraint_info.timeseries
        multiplier = constraint_info.multiplier * inv_dt
        constraint[name] = JuMP.@constraint(
            psi_container.JuMPmodel,
            sum([variable[name, t] for t in time_steps]) <= multiplier * sum(forecast)
        )
    end

    return
end
