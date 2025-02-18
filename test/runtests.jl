using Test, Li

filepath = "/fake/path/jesse/src/coevo/data/2025-02-17/0ae6ee1e-edaf-11ef-09e2-efefb74f9927/2025-02-17T22:15:56.524__K=3160.0__N_host=0__N_patho=0__beta=50__d=0.1__genome_radius=0.1__inner_idx=3__mutprob=0.005__n_genotype=2__p=1e-5__phi=1e-5__q=0.15__r=1.0__rho_c=1__seed=1234.jld2"

@test parse_param_from_filename("seed", filepath) == "1234"
