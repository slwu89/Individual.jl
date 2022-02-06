using Catlab
using Catlab.CategoricalAlgebra
using Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Theories

@present MySchema(FreeSchema) begin
    State::Ob
    StateLabel::AttrType
    statelabel::Attr(State, StateLabel)
end

@acset_type MySchema_index(MySchema,unique_index = [:statelabel])
@acset_type MySchema_noindex(MySchema)

MySchema_index_obj = MySchema_index{String}()
MySchema_noindex_obj = MySchema_noindex{String}()

add_parts!(MySchema_index_obj, :State, 3, statelabel = ["A", "B", "C"])
add_parts!(MySchema_noindex_obj, :State, 3, statelabel = ["A", "B", "C"])

incident(MySchema_index_obj, "C", :statelabel)
incident(MySchema_noindex_obj, "C", :statelabel)