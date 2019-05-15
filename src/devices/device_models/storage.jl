abstract type AbstractStorageForm <: AbstractDeviceFormulation end

struct BookKeeping <: AbstractStorageForm end

struct BookKeepingwReservation <: AbstractStorageForm end

#################################################Storage Variables#################################

function active_power_variables(ps_m::CanonicalModel, 
                                devices::Vector{St}, 
                                time_range::UnitRange{Int64}) where {St <: PSY.Storage}

    add_variable(ps_m, 
                 devices, 
                 time_range, 
                 Symbol("Psin_$(St)"), 
                 false,
                 :nodal_balance_active, 
                 -1)
    add_variable(ps_m, 
                 devices, 
                 time_range, 
                 Symbol("Psout_$(St)"), 
                 false, 
                 :nodal_balance_active)

    return

end


function reactive_power_variables(ps_m::CanonicalModel, 
                                  devices::Vector{St}, 
                                  time_range::UnitRange{Int64}) where {St <: PSY.Storage}

    add_variable(ps_m, 
                 devices, 
                 time_range, 
                 Symbol("Qst_$(St)"), 
                 false, 
                 :nodal_balance_reactive)

    return

end


function energy_storage_variables(ps_m::CanonicalModel, 
                                  devices::Vector{St}, 
                                  time_range::UnitRange{Int64}) where St <: PSY.Storage

    add_variable(ps_m, 
                 devices, 
                 time_range, 
                 Symbol("Est_$(St)"), 
                 false)

    return

end


function storage_reservation_variables(ps_m::CanonicalModel, 
                                       devices::Vector{St}, 
                                       time_range::UnitRange{Int64}) where St <: PSY.Storage

    add_variable(ps_m, 
                 devices, 
                 time_range, 
                 Symbol("Rst_$(St)"),
                 true)

    return

end


###################################################### output power constraints#################################

function active_power_constraints(ps_m::CanonicalModel, 
                                  devices::Vector{St}, 
                                  device_formulation::Type{BookKeeping}, 
                                  system_formulation::Type{S}, 
                                  time_range::UnitRange{Int64}) where {St <: PSY.Storage, 
                                                                       D <: AbstractStorageForm, 
                                                                       S <: PM.AbstractPowerFormulation}

    range_data_in = [(s.name, s.inputactivepowerlimits) for s in devices]
    range_data_out = [(s.name, s.outputactivepowerlimits) for s in devices]

    device_range(ps_m, 
                 range_data_in, 
                 time_range, 
                 Symbol("inputpower_range_$(St)"), 
                 Symbol("Psin_$(St)"))
    
    device_range(ps_m, 
                range_data_out, 
                time_range, 
                Symbol("outputpower_range_$(St)"), 
                Symbol("Psout_$(St)"))                               

    return

end

function active_power_constraints(ps_m::CanonicalModel, 
                                  devices::Vector{St}, 
                                  device_formulation::Type{BookKeepingwReservation}, 
                                  system_formulation::Type{S}, 
                                  time_range::UnitRange{Int64}) where {St <: PSY.Storage, 
                                                                       D <: AbstractStorageForm, 
                                                                       S <: PM.AbstractPowerFormulation}

    range_data_in = [(s.name, s.inputactivepowerlimits) for s in devices]
    range_data_out = [(s.name, s.outputactivepowerlimits) for s in devices]

    reserve_device_semicontinuousrange(ps_m, 
                                       range_data_in, 
                                       time_range, 
                                       Symbol("inputpower_range_$(St)"), 
                                       Symbol("Psin_$(St)"), 
                                       Symbol("Rst_$(St)"))

    reserve_device_semicontinuousrange(ps_m, 
                                       range_data_out, 
                                       time_range, 
                                       Symbol("outputpower_range_$(St)"), 
                                       Symbol("Psout_$(St)"), 
                                       Symbol("Rst_$(St)"))                                       

    return

end


"""
This function adds the reactive  power limits of generators when there are CommitmentVariables
"""
function reactivepower_constraints(ps_m::CanonicalModel, 
                                   devices::Vector{St}, 
                                   device_formulation::Type{D}, 
                                   system_formulation::Type{S}, 
                                   time_range::UnitRange{Int64}) where {St <: PSY.Storage, 
                                                                        D <: AbstractStorageForm, 
                                                                        S <: PM.AbstractPowerFormulation}

    range_data = [(s.name, s.reactivepowerlimits) for s in devices]

    device_range(ps_m, 
                 range_data, 
                 time_range, 
                 Symbol("reactive_range_$(St)"), 
                 Symbol("Qst_$(St)"))

    return

end


# book keeping constraints

function make_efficiency_data(devices::Vector{St}) where {St <: PSY.Storage} 

    names = Vector{String}(undef, length(devices))
    in_out = Vector{Any}(undef, length(devices))

    for (ix,d) in enumerate(devices) 

    names[ix] = d.name
    in_out[ix] = d.efficiency
    
    end

    return names, in_out

end



function energy_balance_constraint(ps_m::CanonicalModel, 
                                   devices::Vector{St}, 
                                   device_formulation::Type{D}, 
                                   system_formulation::Type{S}, 
                                   time_range::UnitRange{Int64},
                                   parameters::Bool) where {St <: PSY.Storage, 
                                                            D <: AbstractStorageForm, 
                                                            S <: PM.AbstractPowerFormulation}

    efficiency_data = make_efficiency_data(devices)

    initial_conditions = get(ps_m.initial_conditions, Symbol("energy_$(St)"), nothing)    
    
    isnothing(initial_conditions) ? storage_energy_init(ps_m, devices, parameters) : true

    energy_balance(ps_m,
                   time_range,
                   initial_conditions,
                   efficiency_data, 
                   Symbol("energy_balance_$(St)"),
                   (Symbol("Psout_$(St)"), Symbol("Psin_$(St)"), Symbol("Est_$(St)")))

    return

end
