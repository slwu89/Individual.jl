# # [SIR example with age structure](@id sir_age)
# Sean L. Wu (@slwu89), 2021-1-22

using Individual.Sampling
using Individual.SchemaBase

using Catlab.Present, Catlab.CSetDataStructures, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Graphs
using Plots
using LinearAlgebra
using Random
using GraphViz

# ## Introduction
# This tutorial shows how to extend the existing abstract ACSet types to incorporate an additional attribute for modeling
# age structure. The model is an age-structured SIR model where the force of infection experienced by an individual is the
# sum of their effective contacts with each age group. The contact matrix ``C_{ij}`` gives the number of daily contacts a person in
# age group ``i`` has with persons in age group ``j``.

# ## Schema

# We need to define a new schema inheriting from `TheoryIBM`. Please note that when we use `@acset_type` to define the type
# for the ACSet data structure for our model, we need to set `:statelabel` as a unique index. This is because the simulation
# framework assumes that there is a one to one mapping between states and their unique labels. Please look at the type definition
# for `IBM` and `SchedulingIBM` in the source files to see what indices are expected, and the [ACSet documentation in Catlab.jl](https://algebraicjulia.github.io/Catlab.jl/stable/apis/categorical_algebra/#Acsets)
# for more information about these data types.

@present TheoryAgeIBM <: TheoryIBM begin
    Age::AttrType
    age::Attr(Person, Age)
end

@abstract_acset_type AbstractAgeIBM <: AbstractIBM
@acset_type AgeIBM(TheoryAgeIBM, index = [:state, :state_update, :age], unique_index = [:statelabel]) <: AbstractAgeIBM

# The schema looks like this. Note that there is an additional attribute in the schema, for age of each individual.
# Note that because age bin will not change over the short course of the epidemic, we don't add another `Attr` "age_update".

to_graphviz(TheoryAgeIBM)

# ## Parameters

# To parameterize the model from ``R_{0}`` and ``\gamma``, we follow the method from ["Social contact patterns and control strategies for influenza in the elderly"](http://www.sherrytowers.com/towers_feng_2012.pdf).
# where ``R_{0}`` is ``\beta / \gamma`` multiplied by the largest eigenvalue of the reciprocal (symmetric) contact matrix. Note that the
# interpretation of ``\beta`` is slightly different in the age-structured model; here it is only the probability of infection given infectious contact,
# in the other examples it was the rate of contact multiplied by the probability of infection given infectious contact.

# We use the estimated contact matrix for Taiwan from ["Projecting social contact matrices in 152 countries using contact surveys and demographic data"](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1005697), given in `contact_unnorm`.
# There are 16 age groups, in 5 year bins, up to age 75, at which all remaining persons are included in the last bin.
# Because the contact matrix is directly estimated from survey data, it is not reciprocal (i.e. the number of contacts sent from
# age group ``i`` to ``j`` must equal the number from ``j`` to ``i``). We use a simple pairwise correction to generate a reciprocal contact matrix.
# For more information on reciprocity in parameterizing contact matrices, please see the article ["Projecting social contact matrices to different demographic structures"](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1006638).

# The vector `pop_TW_actual` gives the census population in 16 bins, which we scale to our population `N`.

N = 1000
I0 = 8
S0 = N - I0
Δt = 0.1
tmax = 100
steps = Int(tmax/Δt)
γ = 1/10 # recovery rate
R0 = 2.5

pop_TW_actual = [1011137, 1041749, 975803, 1213008, 1502279, 1618075, 1621625, 1926961, 2032452, 1755391, 1806638, 1852580, 1684376, 1416638, 903130, 1454933]
pop_TW = N * (pop_TW_actual / sum(pop_TW_actual))
pop_TW = Int.(round.(pop_TW))
N_ages = Float64.(pop_TW)

contact_unnorm = [1.13133995414878	0.557101193757009	0.277403588569526	0.166283484217312	0.243637116538954	0.501429856885401	0.773456505042611	0.664734678057495	0.373030323264845	0.207403718009079	0.219768245286902	0.183713318566528	0.100598824431586	0.0723635363224441	0.0451987854057666	0.0264190015627899
0.522116359073187	5.13993582380529	0.999881750990576	0.256872404884024	0.152965888814777	0.440037571740546	0.81718457664922	0.901816339582795	0.776770796127256	0.324978689513501	0.203946781656598	0.170308924697168	0.114410112258284	0.0766043987718478	0.0377257124824009	0.0309979523804595
0.233720556183555	1.92985936809443	11.0692392115508	0.983950046684279	0.331933259964229	0.36113787699594	0.563341231085396	0.903032808933502	1.17790738474796	0.651636521136264	0.342842258726613	0.173034004951767	0.085317189948624	0.0792891389004607	0.0627981424580935	0.0524757101169723
0.117682987086876	0.345910173819922	3.30103123371644	10.0791939893023	1.50916450884044	0.791285884658043	0.640497694236322	0.824953404104752	1.08583985409548	1.09515652926247	0.535792916941561	0.197364288066501	0.0713874830715285	0.0516466911367817	0.0315463617042823	0.0232625811949096
0.184283846973784	0.180619839511097	0.291480297355471	2.42727014100382	4.36737726042213	2.04934997728767	1.39723781506946	1.20032801881538	1.01070904475343	1.23524796447696	0.800832127889001	0.39902019518293	0.0944429030797382	0.0416382822716035	0.0470826453808244	0.0394951197797532
0.56156192817194	0.342992537769556	0.200122810772951	0.916989232128664	2.3980129020946	4.30977975618343	2.22681401915761	1.59261033191491	1.30238635661337	1.05207634128304	1.00949814315475	0.536928086612407	0.168547286689823	0.0624501078266029	0.0317257423796732	0.0269431049949397
0.817794867047499	1.1441520682733	0.841196707142586	0.551555851206977	1.22865834990464	2.17367993548303	3.72979423098863	2.14929466728635	1.55306730764128	1.11703404262428	0.859302034849221	0.601599257124208	0.256942068421412	0.106203837431624	0.0555526815130332	0.0511357782774989
0.665898107120277	1.15314199919716	0.9740043186808	0.697233734859189	0.825555277703876	1.54165452016297	1.99243882433986	3.25956559702894	2.06558139725526	1.22850364764608	0.791670106907652	0.438605150114473	0.244794735730732	0.148777023280774	0.0869686510606626	0.0349673148163165
0.344192143343282	0.807995410469339	1.14415043227526	1.22438695056131	0.988030619038175	1.30424464223099	1.72028688625099	1.87814450829015	2.90470388452872	1.49758830410338	0.934324050254837	0.330600903622231	0.182537686520201	0.114580140863156	0.0813846406012246	0.0400784886603155
0.235791530653026	0.585194161111923	0.776189668181761	1.67596626847397	0.98479644076933	1.01459833535067	1.25482711892082	1.36074838781177	1.44439037412333	2.06915205205562	0.978401494457824	0.39999986541145	0.147110687316517	0.0835852658511084	0.0775170890988546	0.0761516911425131
0.247247471139332	0.643310594857866	1.05811260803268	1.31212557944165	1.09555967723574	1.35073741525286	1.16660463514035	1.06882688561953	1.37118566862	1.49192984016939	1.73933382380217	0.740193371293642	0.243542236335681	0.109266882350377	0.0798121160310869	0.0833033422190585
0.442684358021657	0.702087727411373	0.662177052932204	0.816859526244507	0.738982978496004	1.2358668685183	1.27567127460055	0.896236373088294	0.950326986928672	0.797183567958301	1.02749599715298	1.51681655407295	0.451707898396268	0.195099577202936	0.0961333966552319	0.0769572529007728
0.327638342195265	0.328285016941782	0.238165901349415	0.354821937305308	0.320966945158153	0.529029787102833	0.677350792373831	0.650949037046765	0.501900491233428	0.407240319726415	0.395920768113556	0.541100083728198	0.836769891969799	0.267847588746602	0.145638827229407	0.059691205799689
0.193568331575816	0.313138348784034	0.2640962452464	0.160094097408356	0.204553272242237	0.325505767060564	0.516407578574901	0.473341415992634	0.438186035505819	0.281001067157269	0.296302451590512	0.375946282497057	0.331749859023468	0.679792406234649	0.173000119847818	0.0702778253123571
0.0963863876721027	0.282393513167451	0.295599962015119	0.30895124164141	0.1384465024105	0.257953175229946	0.27963826844241	0.436956466193058	0.509042820432503	0.403187215044375	0.316140357668137	0.277393058839257	0.385660305905714	0.370945733661385	0.606083091791185	0.185944796718132
0.188903590501605	0.259894019899239	0.37803587788717	0.31873977192663	0.125868047138266	0.160125548829692	0.269195296463481	0.305611946209338	0.348244256184042	0.390220623327373	0.393237304756271	0.240097073151863	0.144076910885202	0.19701354194507	0.184345002762545	0.325239463933643];

contact = (contact_unnorm + transpose(contact_unnorm) .* ( pop_TW * transpose(1 ./ pop_TW))) ./ 2

C = contact
for i = 1:16
    for j = 1:16
        C[i,j] = contact[i,j]*N_ages[i]/N_ages[j]
    end
end

β = R0 * γ / max(eigvals(C)...);

# The initial states are the same as the other tutorials, 1000 individuals, 8 of whom are intially infected.

initial_states = fill("S", N)
initial_states[rand(1:N, I0)] .= "I"
state_labels = ["S", "I", "R"];

# ## Model object

# The `AgeIBM` schema we made needs two type parameters.
# The first `String` is for the set of state labels, inherited from `IBM`.
# The second is for the age attribute.
# Because age is discretized into bins to match the survey data used to parameterize the contact matrix, the attribute type is an integer.  

const SIR = AgeIBM{String, Int64}()
initialize_states(SIR, initial_states, state_labels);

# We need to sample the age bins for each person, such that the sizes of each age bin are correct.

ages = vcat([fill(i, pop_TW[i]) for i in 1:16]...)
shuffle!(ages)
set_subpart!(SIR, 1:N, :age, ages);

# ## Processes

# The force of infection on a person in age class ``i`` is computed according to:
# ```math 
#  \lambda_{i} = \beta \sum\limits_{j} C_{ij} \left( \frac{I_{j}}{N_{j}} \right) 
# ```
# We use a helper function `tabulate_ages` to calculate the infectious population sizes ``I_{j}``.

function tabulate_ages(ages_vec)
    [Float64(sum(ages_vec .== i)) for i = 1:16]
end

function infection_process(t::Int)
    I = get_index_state(SIR, "I")
    I_ages = subpart(SIR, I, :age)
    I_ages = tabulate_ages(I_ages)
    
    λ = β * sum(C * diagm(I_ages ./ N_ages), dims = 2)
    
    S = get_index_state(SIR, "S")
    S_ages = subpart(SIR, S, :age)
    
    λ = λ[S_ages]
    
    S = bernoulli_sample(S, λ, Δt)
    queue_state_update(SIR, S, "I")
end

# The recovery process is the same as in the [basic SIR tutorial](@ref sir_basic).

function recovery_process(t::Int)
    I = get_index_state(SIR, "I")
    I = bernoulli_sample(I, γ, Δt)
    queue_state_update(SIR, I, "R")
end

# ## Simulation

# We use `render_process` to create a rendering (output) process and 
# a matrix giving state counts by time step.
# Then we pass the necessary processes to `simulation_loop` to draw a trajectory and plot the results.

state_out, render_process = render_states(SIR, steps)

simulation_loop(SIR, [infection_process, recovery_process, render_process], steps)

plot(
    (1:steps) * Δt,
    state_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)

# We can also plot the size of the epidemic in each age bin, using a stacked bar chart.

ever_infected = vcat(incident(SIR, [2, 3], :state)...)
ever_infected_ages = subpart(SIR, ever_infected, :age)
ever_infected_ages = [sum(ever_infected_ages .== i) for i = 1:16]

bar(pop_TW, label = false, xlabel = "Age bins", ylabel = "Number")
bar!(ever_infected_ages, label = false)