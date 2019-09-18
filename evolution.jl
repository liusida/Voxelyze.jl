using Distributed
using BSON: @save

include("pancakerobot.jl")

addprocs(300)

const ARG_ENV = parse(Float64, ARGS[1])
const GENERATIONS = 100000
const RATE = [2.0, 2.0, 2.0]

function init_population(n)
	population = []
	for i in 1:n
		push!(population, new_genome())
	end
	return [population...]
end

function new_genome()
	genome = [rand(0:90), rand(0:MAX_PRESS), rand(0:9, 10, 2)]
	return genome
end

function mutate_genome(genome)
	idx = rand(1:3)
	if idx == 1 || idx == 2
		gene = round(RATE[idx]*randn() + genome[idx])
		if gene < 0
			gene = 0
		end
		genome[idx] = gene
	else
		r = rand(1:10)
		c = rand(1:2)
		gene = round(RATE[idx]*randn() + genome[idx][r, c])
		if gene < 0
			gene = 0
		elseif gene > 9
			gene = 9
		end
		genome[idx][r, c] = gene
	end
	return genome
end

function survival_genome((p, p_fit, c, c_fit))
	if p_fit > c_fit
		return p
	else
		return c
	end
end

function survival_fit((p_fit, c_fit))
	if p_fit > c_fit
		return p_fit
	else
		return c_fit
	end
end

parents = init_population(50)
p_fits = pmap(p -> fitness(p, ARG_ENV), parents)
for g in 1:GENERATIONS
	global parents, p_fits
	children = pmap(mutate_genome, parents)
	c_fits = pmap(c -> fitness(c, ARG_ENV), children)
	parents = pmap(survival_genome, zip(parents, p_fits, children, c_fits))
	p_fits = pmap(survival_fit, zip(p_fits, c_fits))

	println("GENERATION: ", g, "    BEST: ", maximum(p_fits))
	@save "genomes/genome_$(lpad(g, 3, "0"))" parents p_fits
end