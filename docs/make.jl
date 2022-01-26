using Documenter, Literate, individual

# Set Literate.jl config if not being compiled on recognized service.
config = Dict{String,String}()
if !(haskey(ENV, "GITHUB_ACTIONS") || haskey(ENV, "GITLAB_CI"))
  config["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/AlgebraicJulia/AlgebraicPetri.jl/blob/gh-pages/dev"
  config["repo_root_url"] = "https://github.com/AlgebraicJulia/AlgebraicPetri.jl/blob/master/docs"
end

const literate_dir = joinpath(@__DIR__, "..", "examples")
const generated_dir = joinpath(@__DIR__, "src", "examples")

for (root, dirs, files) in walkdir(literate_dir)
  out_dir = joinpath(generated_dir, relpath(root, literate_dir))
  for file in files
    f,l = splitext(file)
    if l == ".jl" && !startswith(f, "_")
      Literate.markdown(joinpath(root, file), out_dir;
        config=config, documenter=true, credit=false)
    end
  end
end

makedocs(
  sitename  = "individual.jl",
  pages     = [
    "individual.jl" => "index.md",
    "Examples" => Any[
        "examples/sir-basic.md",
        "examples/sir-scheduling.md",
        "examples/sir-age.md"
      ],
    "Library Reference" => "api.md",
    "Contributing" => "contributing.md"
  ]
)

deploydocs(
  repo = "github.com/slwu89/individual.jl.git",
  branch = "gh-pages"
)