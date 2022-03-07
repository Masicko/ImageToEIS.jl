function generate_random_specification(LSM_ratio, hole_ratio)
  v = Array{Int16}(undef, 100)    
  
    
  hole_length = Int32(round(hole_ratio*100))
  LSM_length = Int32(round((1 - hole_ratio)*LSM_ratio*100))        
  
  v .= i_YSZ
  v[1 : hole_length] .= i_hole
  v[hole_length + 1 : hole_length + LSM_length] .= i_LSM
  return v
end

# generate random matrix of dimensions 
function generate_matrix(dimensions::Union{Tuple, Array}, hole_ratio::Float64, LSM_ratio::Float64)
  return rand(
                          generate_random_specification(LSM_ratio, hole_ratio), 
                          dimensions...
         )
end

function generate_submatrix_to_matrix(matrix, left_upper::Union{Tuple, Array}, right_lower::Union{Tuple, Array}, hole_ratio::Float64, LSM_ratio::Float64)
  submatrix = generate_matrix(right_lower .- left_upper .+ (1,1), hole_ratio, LSM_ratio)
  matrix[left_upper[1] : right_lower[1], left_upper[2] : right_lower[2]] = deepcopy(submatrix)
  return 
end

function generate_submatrix_to_matrix(matrix, right_lower::Union{Tuple, Array}, hole_ratio::Float64, LSM_ratio::Float64)
  generate_submatrix_to_matrix(matrix, (1,1), right_lower::Union{Tuple, Array}, hole_ratio::Float64, LSM_ratio::Float64)
end

function get_default_single_matrix_list()
  # 1 item in the resulting list is
  # 
  # left upper, right lower corner, hole_ratio, LSM_ratio

  first_block_column = 1
  second_block_column = 21
  third_block_column = 41
  width = 42
  height = 80
  return [
    [(1,1), (height, first_block_column), 1.0, 0.5],
    [(1,first_block_column + 1), (height, second_block_column), 0.2, 0.5],
    [(1,second_block_column + 1), (height, third_block_column), 0.2, 1.0],
    [(1,third_block_column + 1), (height, width), 0.2, 1.0],
    #
    [(10, 1), (15, first_block_column), 0.0, 1.0],
    [(40, 1), (45, first_block_column), 0.0, 1.0],
    [(60, 1), (65, first_block_column), 0.0, 1.0]
  ]
end

function generate_matrix(single_matrix_list::Array=get_default_single_matrix_list())
  max_height, max_width = -1, -1
  for submatrix in single_matrix_list
    s = submatrix[2]
    if s[1] > max_height
      max_height = s[1]
    end
    if s[2] > max_width
      max_width = s[2]
    end    
  end  
  
  output_matrix = Matrix(undef, max_height, max_width)
  output_matrix .= -1

  for submatrix in single_matrix_list 
    generate_submatrix_to_matrix(output_matrix, submatrix...)    
  end 
  invalid_single_matrix_list = false
  foreach(x -> x==-1 ?  invalid_single_matrix_list = true : false, output_matrix)
  if invalid_single_matrix_list
    println("ERROR: invalid_single_matrix_list input")
    return throw(Exception)
  else
    return output_matrix
  end
end



function three_columns_domain(LSM_ratio1, LSM_ratio2, LSM_ratio3; 
                              #
                              height_of_contacts=5, positions_of_contacts=[15, 50],
                              #
                              column_width = 5,
                              #
                              height = 70
                              )
  # 1 item in the resulting list is
  # 
  # left upper, right lower corner, hole_ratio, LSM_ratio
  first_block_column = 1
  second_block_column = column_width + 1
  third_block_column = 2*column_width + 1
  fourth_block_column = 3*column_width + 1
  width = fourth_block_column + 1
  
  output = [
    [(1,1), (height, first_block_column), 1.0, 0.5],
    [(1,first_block_column + 1), (height, second_block_column), 0.2, LSM_ratio1],
    [(1,second_block_column + 1), (height, third_block_column), 0.2, LSM_ratio2],
    [(1,third_block_column + 1), (height, fourth_block_column), 0.2, LSM_ratio3],    
    [(1, fourth_block_column + 1), (height, width), 0.0, 1.0]
  ]
  
  # contacts 
  for p_of_contact in positions_of_contacts
    push!(output, [(p_of_contact, 1), (p_of_contact + height_of_contacts - 1, first_block_column), 0.0, 1.0])
  end
  
  return output
end
