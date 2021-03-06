function evaluate_matrix_for_w!(eval, template, w)
  for i in 1:length(template)    
    if typeof(template[i]) <: Function
      eval[i] = template[i](w)
    end
  end
end


function get_prms_from_pairs(pairs)
  p = parameters()
  for pair in pairs
    setfield!(p, Symbol(pair[1]), float(pair[2]))
  end
  return p
end



function material_matrix_to_impedance(
            material_matrix::Array = [1 1 0 1; 0 1 0 1; 0 1 0 1; 0 1 0 1],            
            prms_pairs = [];
            #      
            f_list,            
            #
            complex_type=ComplexF64,
            iterative_solver = false,
            verbose = false
            )
           
  if verbose
    @time params = get_prms_from_pairs(prms_pairs)
    @time header, sp_input, b_real = material_matrix_to_lin_sys(material_matrix, params)          
  
    nz_el_count = length(sp_input[3])
    sp_input_vals_eval = Array{complex_type}(undef, nz_el_count)            
      
    
    Z_list = []
    
    @time for i in 1:nz_el_count
      if !(typeof(sp_input[3][i]) <: Function)
        sp_input_vals_eval[i] = sp_input[3][i]      
      end  
    end
    
    
    b = convert.(complex_type, b_real)
    for f in f_list
      verbose && @show f        
      @time evaluate_matrix_for_w!(sp_input_vals_eval, sp_input[3], 2*pi*f) 
      
      A_eval = sparse(sp_input[1], sp_input[2], sp_input_vals_eval)
      
      #return A_eval, b
      @time if iterative_solver       
        x = bicgstabl(A_eval, b)
      else                
        x = A_eval \ b
      end      
      push!(Z_list, 1/x[1])
    end    
  else
    params = get_prms_from_pairs(prms_pairs)
    header, sp_input, b_real = material_matrix_to_lin_sys(material_matrix, params)          
  
    nz_el_count = length(sp_input[3])
    sp_input_vals_eval = Array{complex_type}(undef, nz_el_count)            
      
    
    Z_list = []
    
    for i in 1:nz_el_count
      if !(typeof(sp_input[3][i]) <: Function)
        sp_input_vals_eval[i] = sp_input[3][i]      
      end  
    end
    
    
    b = convert.(complex_type, b_real)
    for f in f_list
      verbose && @show f        s
      evaluate_matrix_for_w!(sp_input_vals_eval, sp_input[3], 2*pi*f) 
      
      A_eval = sparse(sp_input[1], sp_input[2], sp_input_vals_eval)
      
      #return A_eval, b
      if iterative_solver       
        x = bicgstabl(A_eval, b)
      else                
        x = A_eval \ b
      end      
      push!(Z_list, 1/x[1])
    end 
  end

  
  return f_list, Z_list      
end
