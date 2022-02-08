using Individual

using Individual.Sampling
using Individual.SchemaBase

using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

using Catlab.CSetDataStructures: StructACSet



@present TheoryAgeIBM <: TheoryIBM begin
    Age::AttrType
    age::Attr(Person, Age)

    NAT::AttrType
    nat::Attr(Person, NAT)
    nat_update::Attr(Person, NAT)
end

@abstract_acset_type AbstractAgeIBM <: AbstractIBM
@acset_type AgeIBM(TheoryAgeIBM, index = [:state, :state_update, :age], unique_index = [:statelabel]) <: AbstractAgeIBM



initial_states = rand(["S", "I", "R"], 10)
state_labels = ["S", "I", "R"];


SIR = AgeIBM{String, Int64, Float64}()
initialize_states(SIR, initial_states, state_labels);

s = acset_schema(SIR)

attrs = String.(s.attrs)
attrs = split.(attrs, "_")


update_ix = findall(attrs) do x
    if length(x) < 2
        return false
    else
        return x[end] == "update"
    end
end


attr_ix = map(update_ix) do x
    for i = 1:length(attrs)
        if i == x
            continue
        else
            if attrs[x][1:end-1] == attrs[i]
                return i
            end
        end
    end
end

for i = 1:length(update_ix)
    set_subpart!(SIR, :nat, subpart(SIR, :nat_update))
end