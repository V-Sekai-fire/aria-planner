# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.Domains.Interactivity.Commands.MathHelpers do
  @moduledoc """
  Helper functions for math command operations.

  Provides common functionality for component-wise operations on floatN and floatNxM types.
  Uses aria_math library for vector, matrix, and quaternion operations.
  """

  alias AriaMath.Matrix4.Core, as: Matrix4
  alias AriaMath.Matrix4.Transformations
  alias AriaMath.Quaternion.Core, as: Quaternion
  alias AriaMath.Vector3.Core, as: Vector3

  @doc """
  Applies a binary operation component-wise to two values.
  """
  @spec apply_binary_op(any(), any(), (number(), number() -> number())) :: any()
  def apply_binary_op(a, b, op) when is_number(a) and is_number(b), do: op.(a, b)
  def apply_binary_op({a1, a2}, {b1, b2}, op), do: {op.(a1, b1), op.(a2, b2)}
  def apply_binary_op({a1, a2, a3}, {b1, b2, b3}, op), do: {op.(a1, b1), op.(a2, b2), op.(a3, b3)}
  def apply_binary_op({a1, a2, a3, a4}, {b1, b2, b3, b4}, op), do: {op.(a1, b1), op.(a2, b2), op.(a3, b3), op.(a4, b4)}

  def apply_binary_op(a, b, op) when is_tuple(a) and is_tuple(b) do
    Tuple.to_list(a)
    |> Enum.zip(Tuple.to_list(b))
    |> Enum.map(fn {x, y} -> op.(x, y) end)
    |> List.to_tuple()
  end

  def apply_binary_op(a, b, op) do
    op.(a, b)
  rescue
    _ -> {:error, "Cannot apply operation to incompatible types"}
  end

  @doc """
  Applies a unary operation component-wise to a value.
  """
  @spec apply_unary_op(any(), (number() -> number())) :: any()
  def apply_unary_op(a, op) when is_number(a), do: op.(a)
  def apply_unary_op({a1, a2}, op), do: {op.(a1), op.(a2)}
  def apply_unary_op({a1, a2, a3}, op), do: {op.(a1), op.(a2), op.(a3)}
  def apply_unary_op({a1, a2, a3, a4}, op), do: {op.(a1), op.(a2), op.(a3), op.(a4)}

  def apply_unary_op(a, op) when is_tuple(a) do
    a
    |> Tuple.to_list()
    |> Enum.map(op)
    |> List.to_tuple()
  end

  def apply_unary_op(a, op) do
    op.(a)
  rescue
    _ -> {:error, "Cannot apply operation to incompatible type"}
  end

  @doc """
  Gets a socket value, returning an error if not found.
  """
  @spec get_socket_value(map(), String.t(), String.t()) :: {:ok, any()} | {:error, String.t()}
  def get_socket_value(state, node_id, socket_id) do
    alias AriaPlanner.Domains.Interactivity.Predicates.SocketValue

    value = SocketValue.get(state, node_id, socket_id)

    if value != nil do
      {:ok, value}
    else
      {:error, "Socket #{socket_id} on node #{node_id} has no value"}
    end
  end

  @doc """
  Checks if graph is active.
  """
  @spec check_graph_active(map()) :: :ok | {:error, String.t()}
  def check_graph_active(state) do
    alias AriaPlanner.Domains.Interactivity.Predicates.GraphActive

    if GraphActive.active?(state) do
      :ok
    else
      {:error, "Graph must be active to execute operations"}
    end
  end

  # Helper functions for specific operations (public for use in command modules)

  @doc """
  Sign operation: returns -1 if a < 0, a if a == 0, +1 if a > 0
  """
  @spec sign_op(number()) :: number()
  def sign_op(a) when is_number(a) do
    cond do
      a < 0 -> -1
      a == 0 -> a
      a > 0 -> 1
    end
  end

  def sign_op(a) when is_tuple(a), do: apply_unary_op(a, &sign_op/1)

  @spec round_op(number()) :: number()
  def round_op(a) when is_number(a) do
    if a < 0 do
      -trunc(-a + 0.5)
    else
      trunc(a + 0.5)
    end
  end

  def round_op(a) when is_tuple(a), do: apply_unary_op(a, &round_op/1)

  @spec fract_op(number()) :: number()
  def fract_op(a) when is_number(a) do
    a - floor(a)
  end

  def fract_op(a) when is_tuple(a), do: apply_unary_op(a, &fract_op/1)

  @spec saturate_op(number()) :: number()
  def saturate_op(a) when is_number(a) do
    min(max(a, 0), 1)
  end

  def saturate_op(a) when is_tuple(a), do: apply_unary_op(a, &saturate_op/1)

  @spec log2_op(number()) :: number()
  def log2_op(a) when is_number(a) do
    :math.log(a) / :math.log(2)
  end

  def log2_op(a) when is_tuple(a), do: apply_unary_op(a, &log2_op/1)

  @spec log10_op(number()) :: number()
  def log10_op(a) when is_number(a) do
    :math.log(a) / :math.log(10)
  end

  def log10_op(a) when is_tuple(a), do: apply_unary_op(a, &log10_op/1)

  @spec cbrt_op(number()) :: number()
  def cbrt_op(a) when is_number(a) do
    :math.pow(a, 1.0 / 3.0)
  end

  def cbrt_op(a) when is_tuple(a), do: apply_unary_op(a, &cbrt_op/1)

  @spec rad_op(number()) :: number()
  def rad_op(a) when is_number(a) do
    a * :math.pi() / 180.0
  end

  def rad_op(a) when is_tuple(a), do: apply_unary_op(a, &rad_op/1)

  @spec deg_op(number()) :: number()
  def deg_op(a) when is_number(a) do
    a * 180.0 / :math.pi()
  end

  def deg_op(a) when is_tuple(a), do: apply_unary_op(a, &deg_op/1)

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames

  @spec is_nan_op(number()) :: boolean()
  def is_nan_op(a) when is_float(a) do
    # NaN is not equal to itself - this is the correct way to check for NaN
    # credo:disable-for-next-line Credo.Check.Warning.OperationOnSameValues
    a != a
  end

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  def is_nan_op(_a) do
    false
  end

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  @spec is_inf_op(number()) :: boolean()
  def is_inf_op(a) when is_number(a) do
    # Check if division by zero produces infinity
    # a / a can produce infinity or NaN, not always 1 (e.g., 0/0 = NaN, inf/inf = NaN)
    # Using a helper to avoid Credo false positive warning
    divisor = a
    # credo:disable-for-next-line Credo.Check.Warning.OperationWithConstantResult
    division_result = a / divisor

    case division_result do
      # NaN (0/0) - NaN is not equal to itself
      # credo:disable-for-next-line Credo.Check.Warning.OperationOnSameValues
      x when x != x -> true
      _ -> false
    end
  end

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  def is_inf_op(_a) do
    false
  end

  @spec length_op(tuple()) :: number()
  def length_op({a1, a2, a3}) when is_number(a1) and is_number(a2) and is_number(a3) do
    # Use aria_math for 3D vectors
    Vector3.length({a1, a2, a3})
  end

  def length_op(a) when is_tuple(a) do
    # For float2, float4, or other sizes, use component-wise operation
    a
    |> Tuple.to_list()
    |> Enum.map(fn x -> x * x end)
    |> Enum.sum()
    |> :math.sqrt()
  end

  @spec normalize_op(tuple()) :: {tuple(), boolean()}
  def normalize_op({a1, a2, a3}) when is_number(a1) and is_number(a2) and is_number(a3) do
    # Use aria_math for 3D vectors (glTF spec compliant)
    Vector3.normalize({a1, a2, a3})
  end

  def normalize_op(a) when is_tuple(a) do
    # glTF spec: math/normalize - returns {value, isValid}
    # For float2, float4, or other sizes, use custom implementation
    length = length_op(a)

    # Step 2: If length is zero, NaN, or positive infinity, isValid = false and value = vector of zeros
    if length == 0.0 or is_nan_op(length) or is_finite(length) == false do
      zero_vector = List.duplicate(0.0, tuple_size(a)) |> List.to_tuple()
      {zero_vector, false}
    else
      # Step 3: If length is positive finite, isValid = true and value = normalized vector
      normalized =
        a
        |> Tuple.to_list()
        |> Enum.map(fn x -> x / length end)
        |> List.to_tuple()

      {normalized, true}
    end
  end

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  @spec is_finite(number()) :: boolean()
  defp is_finite(x) when is_float(x) do
    not is_nan_op(x) and not is_inf_op(x)
  end

  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  defp is_finite(_x) do
    true
  end

  @spec eq_op(number(), number()) :: boolean()
  def eq_op(a, b) when is_number(a) and is_number(b) do
    a == b
  end

  @spec lt_op(number(), number()) :: boolean()
  def lt_op(a, b) when is_number(a) and is_number(b) do
    a < b
  end

  @spec le_op(number(), number()) :: boolean()
  def le_op(a, b) when is_number(a) and is_number(b) do
    a <= b
  end

  @spec gt_op(number(), number()) :: boolean()
  def gt_op(a, b) when is_number(a) and is_number(b) do
    a > b
  end

  @spec ge_op(number(), number()) :: boolean()
  def ge_op(a, b) when is_number(a) and is_number(b) do
    a >= b
  end

  @spec dot_op(tuple(), tuple()) :: number()
  def dot_op({a1, a2, a3}, {b1, b2, b3}) when is_number(a1) and is_number(a2) and is_number(a3) do
    # Use aria_math for 3D vectors
    Vector3.dot({a1, a2, a3}, {b1, b2, b3})
  end

  def dot_op(a, b) when is_tuple(a) and is_tuple(b) do
    # For float2, float4, or other sizes, use component-wise operation
    a
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(b))
    |> Enum.map(fn {x, y} -> x * y end)
    |> Enum.sum()
  end

  @spec cross_op({number(), number(), number()}, {number(), number(), number()}) ::
          {number(), number(), number()}
  def cross_op({a1, a2, a3}, {b1, b2, b3}) do
    # Use aria_math for 3D cross product
    Vector3.cross({a1, a2, a3}, {b1, b2, b3})
  end

  @spec clamp_op(number(), number(), number()) :: number()
  def clamp_op(a, b, c) when is_number(a) and is_number(b) and is_number(c) do
    min_val = min(b, c)
    max_val = max(b, c)
    min(max(a, min_val), max_val)
  end

  def clamp_op(a, b, c) when is_tuple(a) and is_tuple(b) and is_tuple(c) do
    min_val = apply_binary_op(b, c, &min/2)
    max_val = apply_binary_op(b, c, &max/2)
    apply_binary_op(apply_binary_op(a, min_val, &max/2), max_val, &min/2)
  end

  @spec mix_op(number(), number(), number()) :: number()
  def mix_op(a, b, c) when is_number(a) and is_number(b) and is_number(c) do
    (1 - c) * a + c * b
  end

  def mix_op(a, b, c) when is_tuple(a) and is_tuple(b) and is_number(c) do
    apply_binary_op(a, b, fn x, y -> (1 - c) * x + c * y end)
  end

  @spec select_op(boolean(), any(), any()) :: any()
  def select_op(condition, a, _b) when condition == true, do: a
  def select_op(condition, _a, b) when condition == false, do: b

  # Matrix conversion helpers (glTF uses column-major, aria_math uses row-major)
  @spec matrix_column_major_to_row_major(tuple()) :: Nx.Tensor.t()
  defp matrix_column_major_to_row_major(matrix) when is_tuple(matrix) do
    # Convert column-major tuple to row-major Nx tensor
    size = trunc(:math.sqrt(tuple_size(matrix)))
    cols = matrix |> Tuple.to_list() |> Enum.chunk_every(size)
    rows = Enum.zip_with(cols, fn col -> col end)
    rows |> Nx.tensor(type: :f32)
  end

  @spec matrix_row_major_to_column_major(Nx.Tensor.t()) :: tuple()
  defp matrix_row_major_to_column_major(tensor) do
    # Convert row-major Nx tensor to column-major tuple
    rows = Nx.to_list(tensor)
    # Transpose to get columns, then flatten
    cols = rows |> Enum.zip() |> Enum.map(fn col -> Tuple.to_list(col) end)
    cols |> List.flatten() |> List.to_tuple()
  end

  # Matrix operations (glTF uses column-major order: [c0r0, c0r1, c1r0, c1r1] for 2x2)
  @spec transpose_op(tuple()) :: tuple()
  def transpose_op(matrix) when is_tuple(matrix) and tuple_size(matrix) == 16 do
    # Use aria_math for 4x4 matrices
    matrix
    |> matrix_column_major_to_row_major()
    |> Matrix4.transpose()
    |> matrix_row_major_to_column_major()
  end

  def transpose_op(matrix) when is_tuple(matrix) do
    # Matrix is stored in column-major order: [c0r0, c0r1, c1r0, c1r1] for 2x2
    # Input {1,3,2,4} means: col0=[1,3], col1=[2,4], so matrix = [[1,2],[3,4]]
    # Transpose: [[1,3],[2,4]] = col0=[1,2], col1=[3,4], so result = {1,2,3,4}
    size = trunc(:math.sqrt(tuple_size(matrix)))
    cols = matrix |> Tuple.to_list() |> Enum.chunk_every(size)
    # Convert columns to rows: zip columns together
    rows = cols |> Enum.zip() |> Enum.map(fn row -> Tuple.to_list(row) end)
    # Transpose rows: zip rows to get transpose rows
    transpose_rows = rows |> Enum.zip() |> Enum.map(fn row -> Tuple.to_list(row) end)
    # Convert transpose rows to column-major: col0 = [row0[0], row1[0]], col1 = [row0[1], row1[1]], etc.
    for i <- 0..(size - 1) do
      for row <- transpose_rows do
        Enum.at(row, i)
      end
    end
    |> List.flatten()
    |> List.to_tuple()
  end

  @spec determinant_op(tuple()) :: number()
  def determinant_op(matrix) when is_tuple(matrix) and tuple_size(matrix) == 16 do
    # Use aria_math for 4x4 matrices
    matrix
    |> matrix_column_major_to_row_major()
    |> Matrix4.determinant()
  end

  def determinant_op(matrix) when is_tuple(matrix) do
    # For 2x2, 3x3, or other sizes, use custom implementation
    size = trunc(:math.sqrt(tuple_size(matrix)))
    cols = matrix |> Tuple.to_list() |> Enum.chunk_every(size)
    rows = Enum.zip_with(cols, fn col -> col end)
    det_impl(rows, size)
  end

  defp det_impl([[a]], 1), do: a

  defp det_impl(matrix, size) when size == 2 do
    [[a, b], [c, d]] = matrix
    a * d - b * c
  end

  defp det_impl(matrix, size) when size == 3 do
    [[a, b, c], [d, e, f], [g, h, i]] = matrix
    a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
  end

  defp det_impl(matrix, size) when size == 4 do
    # 4x4 determinant using cofactor expansion
    [[a, b, c, d], [e, f, g, h], [i, j, k, l], [m, n, o, p]] = matrix

    a * det_impl([[f, g, h], [j, k, l], [n, o, p]], 3) -
      b * det_impl([[e, g, h], [i, k, l], [m, o, p]], 3) +
      c * det_impl([[e, f, h], [i, j, l], [m, n, p]], 3) -
      d * det_impl([[e, f, g], [i, j, k], [m, n, o]], 3)
  end

  @spec inverse_op(tuple()) :: {tuple(), boolean()}
  def inverse_op(matrix) when is_tuple(matrix) and tuple_size(matrix) == 16 do
    # Use aria_math for 4x4 matrices (glTF spec compliant)
    {inverse_tensor, is_valid} =
      matrix
      |> matrix_column_major_to_row_major()
      |> Matrix4.invert()

    inverse_tuple = matrix_row_major_to_column_major(inverse_tensor)
    {inverse_tuple, is_valid}
  end

  def inverse_op(matrix) when is_tuple(matrix) do
    # For 2x2, 3x3, or other sizes, use custom implementation
    # glTF spec: math/inverse - returns {value, isValid}
    det = determinant_op(matrix)

    # Step 2: If determinant is zero, NaN, or infinity, isValid = false and value = matrix of zeros
    if det == 0.0 or is_nan_op(det) or is_inf_op(det) do
      size = tuple_size(matrix)
      zero_matrix = List.duplicate(0.0, size) |> List.to_tuple()
      {zero_matrix, false}
    else
      # Step 3: If determinant is finite and non-zero, isValid = true and value = inverse
      result = adjugate_and_scale(matrix, det)
      {result, true}
    end
  end

  defp adjugate_and_scale(matrix, det) do
    # Matrix is stored in column-major order: chunking by size gives columns
    # Adjugate needs rows, so transpose to interpretation
    size = trunc(:math.sqrt(tuple_size(matrix)))
    cols = matrix |> Tuple.to_list() |> Enum.chunk_every(size)
    rows = Enum.zip_with(cols, fn col -> col end)
    cofactor = adjugate(rows, size)
    # Adjugate is transpose of cofactor matrix
    # Cofactor is in row-major: [[a,b],[c,d]], adjugate = [[a,c],[b,d]]
    adjugate_rows = cofactor |> Enum.zip() |> Enum.map(fn col -> Tuple.to_list(col) end)
    # Calculate inverse: (1/det) * adjugate
    inverse_rows = adjugate_rows |> Enum.map(fn row -> Enum.map(row, fn x -> x / det end) end)
    # Convert inverse (in row-major) back to column-major
    # Row-major: [[a,b],[c,d]] -> Column-major: {a,c,b,d}
    inverse_cols = inverse_rows |> Enum.zip() |> Enum.map(fn col -> Tuple.to_list(col) end)
    inverse_cols |> List.flatten() |> List.to_tuple()
  end

  defp adjugate(rows, size) do
    for i <- 0..(size - 1) do
      for j <- 0..(size - 1) do
        minor = minor_matrix(rows, i, j, size)
        sign = if rem(i + j, 2) == 0, do: 1, else: -1
        sign * det_impl(minor, size - 1)
      end
    end
  end

  defp minor_matrix(rows, skip_i, skip_j, _size) do
    rows
    |> Enum.with_index()
    |> Enum.reject(fn {_row, i} -> i == skip_i end)
    |> Enum.map(fn {row, _i} ->
      row |> Enum.with_index() |> Enum.reject(fn {_val, j} -> j == skip_j end) |> Enum.map(fn {val, _j} -> val end)
    end)
  end

  @spec mat_mul_op(tuple(), tuple()) :: tuple()
  def mat_mul_op(a, b) when is_tuple(a) and is_tuple(b) and tuple_size(a) == 16 and tuple_size(b) == 16 do
    # Use aria_math for 4x4 matrices
    a_tensor = matrix_column_major_to_row_major(a)
    b_tensor = matrix_column_major_to_row_major(b)
    result_tensor = Matrix4.multiply(a_tensor, b_tensor)
    matrix_row_major_to_column_major(result_tensor)
  end

  def mat_mul_op(a, b) when is_tuple(a) and is_tuple(b) do
    size_a = trunc(:math.sqrt(tuple_size(a)))
    size_b = trunc(:math.sqrt(tuple_size(b)))
    if size_a != size_b, do: {:error, "Matrix dimensions must match"}, else: mat_multiply(a, b, size_a)
  end

  defp mat_multiply(a, b, size) do
    # Matrices are stored in column-major order: chunking by size gives columns
    # Matrix multiplication: A * B where A and B are in column-major
    # Need to interpret as rows for multiplication, then convert result back to column-major
    cols_a = a |> Tuple.to_list() |> Enum.chunk_every(size)
    cols_b = b |> Tuple.to_list() |> Enum.chunk_every(size)
    # Convert columns to rows: zip columns together
    rows_a = cols_a |> Enum.zip() |> Enum.map(fn row -> Tuple.to_list(row) end)
    rows_b = cols_b |> Enum.zip() |> Enum.map(fn row -> Tuple.to_list(row) end)
    # Multiply: result[i][j] = sum over k of rows_a[i][k] * rows_b[k][j]
    result_rows =
      for i <- 0..(size - 1) do
        row_a = Enum.at(rows_a, i)

        for j <- 0..(size - 1) do
          Enum.reduce(0..(size - 1), 0, fn k, acc ->
            row_b_k = Enum.at(rows_b, k)
            acc + Enum.at(row_a, k) * Enum.at(row_b_k, j)
          end)
        end
      end

    # Convert result rows back to column-major: transpose rows to columns
    # result_rows = [[r0c0, r0c1], [r1c0, r1c1]]
    # We want: col0 = [r0c0, r1c0], col1 = [r0c1, r1c1]
    result_rows
    |> Enum.zip()
    |> Enum.map(fn col -> Tuple.to_list(col) end)
    |> List.flatten()
    |> List.to_tuple()
  end

  @spec mat_compose_op(tuple(), tuple(), tuple()) :: tuple()
  def mat_compose_op(translation, rotation, scale)
      when is_tuple(translation) and is_tuple(rotation) and is_tuple(scale) do
    # Compose 4x4 transform matrix: T * R * S
    # Translation is float3, rotation is quaternion (float4), scale is float3
    # Returns 4x4 matrix (16 floats)
    t =
      translation
      |> Tuple.to_list()
      |> then(fn [x, y, z] -> [x, y, z, 1.0] end)

    r = quaternion_to_matrix(rotation)
    s = scale_matrix(scale)
    # Multiply: T * R * S
    mat_mul_op(mat_mul_op(translation_matrix(t), r), s)
  end

  defp translation_matrix([x, y, z, _w]) do
    # glTF column-major order: [c0r0, c0r1, c0r2, c0r3, c1r0, c1r1, ...]
    # Translation matrix: T = [[1,0,0,tx], [0,1,0,ty], [0,0,1,tz], [0,0,0,1]]
    # Column-major: [1,0,0,0, 0,1,0,0, 0,0,1,0, tx,ty,tz,1]
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, z, 1.0}
  end

  defp scale_matrix(scale) do
    # glTF column-major order
    # Scale matrix: S = [[sx,0,0,0], [0,sy,0,0], [0,0,sz,0], [0,0,0,1]]
    # Column-major: [sx,0,0,0, 0,sy,0,0, 0,0,sz,0, 0,0,0,1]
    [sx, sy, sz] = scale |> Tuple.to_list()
    {sx, 0.0, 0.0, 0.0, 0.0, sy, 0.0, 0.0, 0.0, sz, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  defp quaternion_to_matrix({x, y, z, w}) do
    # Convert quaternion to rotation matrix (glTF uses {x, y, z, w} order)
    # Formula from spec: matCompose rotation matrix (shown in row-major, but glTF stores column-major)
    xx = x * x
    yy = y * y
    zz = z * z
    xy = x * y
    xz = x * z
    yz = y * z
    xw = x * w
    yw = y * w
    zw = z * w
    # Rotation matrix in row-major notation:
    # [[1-2(yy+zz), 2(xy-zw),   2(xz+yw),   0],
    #  [2(xy+zw),   1-2(xx+zz), 2(yz-xw),   0],
    #  [2(xz-yw),   2(yz+xw),   1-2(xx+yy), 0],
    #  [0,          0,          0,          1]]
    # Convert to column-major: {col0, col1, col2, col3} where each col is [row0, row1, row2, row3]
    {
      # col0, row0
      1.0 - 2.0 * (yy + zz),
      # col0, row1
      2.0 * (xy + zw),
      # col0, row2
      2.0 * (xz - yw),
      # col0, row3
      0.0,
      # col1, row0
      2.0 * (xy - zw),
      # col1, row1
      1.0 - 2.0 * (xx + zz),
      # col1, row2
      2.0 * (yz + xw),
      # col1, row3
      0.0,
      # col2, row0
      2.0 * (xz + yw),
      # col2, row1
      2.0 * (yz - xw),
      # col2, row2
      1.0 - 2.0 * (xx + yy),
      # col2, row3
      0.0,
      # col3, row0
      0.0,
      # col3, row1
      0.0,
      # col3, row2
      0.0,
      # col3, row3
      1.0
    }
  end

  @spec mat_decompose_op(tuple()) :: {tuple(), tuple(), tuple(), boolean()} | {:error, String.t()}
  def mat_decompose_op(matrix) when is_tuple(matrix) and tuple_size(matrix) == 16 do
    # glTF spec: matDecompose - full 11-step algorithm
    # Matrix is stored in column-major order: [c0r0, c0r1, c0r2, c0r3, c1r0, c1r1, ...]
    # For 4x4: indices 0-3 are column 0, 4-7 are column 1, 8-11 are column 2, 12-15 are column 3
    list = Tuple.to_list(matrix)

    # Step 1: Check fourth row (indices 12, 13, 14, 15)
    [a_30, a_31, a_32, a_33] = Enum.slice(list, 12, 4)
    threshold = 1.0e-6

    if abs(a_30) > threshold or abs(a_31) > threshold or abs(a_32) > threshold or abs(a_33 - 1.0) > threshold do
      # Invalid - goto step 11
      {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 1.0}, {1.0, 1.0, 1.0}, false}
    else
      # Step 2: Calculate scale from column lengths (first three columns)
      # Column 0: indices 0, 1, 2
      # Column 1: indices 4, 5, 6
      # Column 2: indices 8, 9, 10
      [a_00, a_10, a_20] = Enum.slice(list, 0, 3)
      [a_01, a_11, a_21] = Enum.slice(list, 4, 3)
      [a_02, a_12, a_22] = Enum.slice(list, 8, 3)

      sx = :math.sqrt(a_00 * a_00 + a_10 * a_10 + a_20 * a_20)
      sy = :math.sqrt(a_01 * a_01 + a_11 * a_11 + a_21 * a_21)
      sz = :math.sqrt(a_02 * a_02 + a_12 * a_12 + a_22 * a_22)

      # Step 3: Check if scales are valid
      if not is_finite(sx) or not is_finite(sy) or not is_finite(sz) or sx == 0.0 or sy == 0.0 or sz == 0.0 do
        # Invalid - goto step 11
        {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 1.0}, {1.0, 1.0, 1.0}, false}
      else
        # Step 4: Build matrix B by dividing each column by its scale
        b_00 = a_00 / sx
        b_10 = a_10 / sx
        b_20 = a_20 / sx
        b_01 = a_01 / sy
        b_11 = a_11 / sy
        b_21 = a_21 / sy
        b_02 = a_02 / sz
        b_12 = a_12 / sz
        b_22 = a_22 / sz

        # Step 5: Check determinant of B
        det_b =
          b_00 * (b_11 * b_22 - b_12 * b_21) - b_01 * (b_10 * b_22 - b_12 * b_20) + b_02 * (b_10 * b_21 - b_11 * b_20)

        if abs(abs(det_b) - 1.0) > threshold do
          # Invalid - goto step 11
          {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 1.0}, {1.0, 1.0, 1.0}, false}
        else
          # Step 6: Extract translation (first three elements of fourth column: indices 12, 13, 14)
          translation = {a_30, a_31, a_32}

          # Step 7 & 8: Handle negative determinant
          {scale, b_00, b_10, b_20, b_01, b_11, b_21, b_02, b_12, b_22} =
            if det_b < 0.0 do
              # Use first option: negate first column
              {{-sx, sy, sz}, -b_00, -b_10, -b_20, b_01, b_11, b_21, b_02, b_12, b_22}
            else
              {{sx, sy, sz}, b_00, b_10, b_20, b_01, b_11, b_21, b_02, b_12, b_22}
            end

          # Step 9: Convert matrix B to quaternion
          b_matrix = {b_00, b_01, b_02, 0.0, b_10, b_11, b_12, 0.0, b_20, b_21, b_22, 0.0, 0.0, 0.0, 0.0, 1.0}
          rotation = matrix_to_quaternion(b_matrix)

          # Step 10: Set isValid to true
          {translation, rotation, scale, true}
        end
      end
    end
  end

  defp matrix_to_quaternion({m00, m01, m02, _m03, m10, m11, m12, _m13, m20, m21, m22, _m23, _m30, _m31, _m32, _m33}) do
    # Convert rotation matrix to quaternion (glTF uses {x, y, z, w} order)
    trace = m00 + m11 + m22

    if trace > 0.0 do
      s = 2.0 * :math.sqrt(trace + 1.0)
      x = (m21 - m12) / s
      y = (m02 - m20) / s
      z = (m10 - m01) / s
      w = 0.25 * s
      {x, y, z, w}
    else
      if m00 > m11 and m00 > m22 do
        s = 2.0 * :math.sqrt(1.0 + m00 - m11 - m22)
        x = 0.25 * s
        y = (m01 + m10) / s
        z = (m12 + m21) / s
        w = (m21 - m12) / s
        {x, y, z, w}
      else
        if m11 > m22 do
          s = 2.0 * :math.sqrt(1.0 + m11 - m00 - m22)
          x = (m01 + m10) / s
          y = 0.25 * s
          z = (m12 + m21) / s
          w = (m02 - m20) / s
          {x, y, z, w}
        else
          s = 2.0 * :math.sqrt(1.0 + m22 - m00 - m11)
          x = (m02 + m20) / s
          y = (m12 + m21) / s
          z = 0.25 * s
          w = (m10 - m01) / s
          {x, y, z, w}
        end
      end
    end
  end

  # Quaternion operations (glTF uses {x, y, z, w} order)
  @spec quat_conjugate_op(tuple()) :: tuple()
  def quat_conjugate_op({x, y, z, w}) do
    # Use aria_math for quaternion conjugation (glTF spec compliant)
    Quaternion.conjugate({x, y, z, w})
  end

  @spec quat_mul_op(tuple(), tuple()) :: tuple()
  def quat_mul_op({a_x, a_y, a_z, a_w}, {b_x, b_y, b_z, b_w}) do
    # Use aria_math for quaternion multiplication (glTF spec compliant)
    Quaternion.multiply({a_x, a_y, a_z, a_w}, {b_x, b_y, b_z, b_w})
  end

  @spec quat_angle_between_op(tuple(), tuple()) :: number()
  def quat_angle_between_op(q1, q2) do
    # Use aria_math for quaternion angle between
    alias AriaMath.Quaternion
    Quaternion.angle_between(q1, q2)
  end

  @spec quat_from_axis_angle_op(tuple(), number()) :: tuple()
  def quat_from_axis_angle_op(axis, angle) when is_tuple(axis) and is_number(angle) do
    # Use aria_math for quaternion from axis-angle (glTF spec compliant)
    alias AriaMath.Quaternion
    Quaternion.from_axis_angle(axis, angle)
  end

  @spec quat_to_axis_angle_op(tuple()) :: {tuple(), number()}
  def quat_to_axis_angle_op({a_x, a_y, a_z, a_w}) do
    # Use aria_math for quaternion to axis-angle (glTF spec compliant)
    alias AriaMath.Quaternion
    Quaternion.to_axis_angle({a_x, a_y, a_z, a_w})
  end

  @spec quat_from_directions_op(tuple(), tuple()) :: tuple()
  def quat_from_directions_op(from, to) when is_tuple(from) and is_tuple(to) do
    # Use aria_math for quaternion from directions (glTF spec compliant)
    alias AriaMath.Quaternion
    Quaternion.from_directions(from, to)
  end

  @spec quat_from_up_forward_op(tuple(), tuple()) :: tuple()
  def quat_from_up_forward_op(up, forward) when is_tuple(up) and is_tuple(forward) do
    # Create quaternion from up and forward vectors (orthonormal basis)
    {up_norm, _} = normalize_op(up)
    {forward_norm, _} = normalize_op(forward)
    {right, _} = normalize_op(cross_op(forward_norm, up_norm))
    {new_up, _} = normalize_op(cross_op(right, forward_norm))
    # Build rotation matrix from basis vectors, then convert to quaternion
    {r1, r2, r3} = right
    {u1, u2, u3} = new_up
    {f1, f2, f3} = forward_norm
    matrix = {r1, r2, r3, 0.0, u1, u2, u3, 0.0, f1, f2, f3, 0.0, 0.0, 0.0, 0.0, 1.0}
    matrix_to_quaternion(matrix)
  end

  @spec quat_slerp_op(tuple(), tuple(), number()) :: tuple()
  def quat_slerp_op(a, b, c) when is_tuple(a) and is_tuple(b) and is_number(c) do
    # Use aria_math for quaternion slerp (glTF spec compliant)
    alias AriaMath.Quaternion
    Quaternion.slerp(a, b, c)
  end

  # Transform operations
  @spec rotate2d_op(tuple(), number()) :: tuple()
  def rotate2d_op({x, y}, angle) when is_number(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)
    {x * c - y * s, x * s + y * c}
  end

  @spec rotate3d_op(tuple(), tuple()) :: tuple()
  def rotate3d_op({vx, vy, vz}, {qx, qy, qz, qw}) do
    # Implement quaternion rotation per glTF spec formula:
    # v' = v + 2 * (qv × (qv × v) + qw * (qv × v))
    # where qv = {qx, qy, qz} is the vector part of the quaternion
    # Using cross product for vector operations
    qv = {qx, qy, qz}
    v = {vx, vy, vz}

    # qv × v
    {cx1, cy1, cz1} = cross_op(qv, v)

    # qv × (qv × v)
    {cx2, cy2, cz2} = cross_op(qv, {cx1, cy1, cz1})

    # qw * (qv × v)
    {wx, wy, wz} = {qw * cx1, qw * cy1, qw * cz1}

    # v + 2 * (qv × (qv × v) + qw * (qv × v))
    {vx + 2.0 * (cx2 + wx), vy + 2.0 * (cy2 + wy), vz + 2.0 * (cz2 + wz)}
  end

  @spec transform_op(tuple(), tuple()) :: tuple()
  def transform_op(vector, matrix) when is_tuple(vector) and is_tuple(matrix) and tuple_size(matrix) == 16 do
    # Use aria_math for matrix transformation (with column-major conversion)
    alias AriaMath.Matrix4.Transformations
    vector_tensor = Nx.tensor(Tuple.to_list(vector), type: :f32)
    matrix_tensor = matrix_column_major_to_row_major(matrix)
    result_tensor = Transformations.transform_point(matrix_tensor, vector_tensor)
    result_tensor |> Nx.to_list() |> List.to_tuple()
  end

  # Bitwise operations
  @spec clz_op(integer()) :: integer()
  def clz_op(a) when is_integer(a) do
    # Count leading zeros: if a is 0, return 32; if negative, return 0
    if a == 0 do
      32
    else
      if a < 0 do
        0
      else
        # Count leading zeros using bit manipulation
        count_leading_zeros(a)
      end
    end
  end

  defp count_leading_zeros(n) when n > 0 do
    # Convert to 32-bit unsigned, count leading zeros
    unsigned = if n < 0, do: n + 0x100000000, else: n
    bits = Integer.digits(unsigned, 2) |> Enum.reverse()
    # Pad to 32 bits
    padded = bits ++ List.duplicate(0, 32 - length(bits))
    # Count leading zeros
    Enum.take_while(padded, &(&1 == 0)) |> length()
  end

  @spec ctz_op(integer()) :: integer()
  def ctz_op(a) when is_integer(a) do
    # Count trailing zeros: number of trailing zero bits
    if a == 0 do
      32
    else
      # Count trailing zeros using bit manipulation
      count_trailing_zeros(a)
    end
  end

  defp count_trailing_zeros(n) when n != 0 do
    # Use bitwise operations to count trailing zeros
    # If n is negative, work with two's complement
    unsigned = if n < 0, do: n + 0x100000000, else: n
    bits = Integer.digits(unsigned, 2) |> Enum.reverse()
    # Count trailing zeros (from right)
    Enum.take_while(bits, &(&1 == 0)) |> length()
  end

  @spec popcnt_op(integer()) :: integer()
  def popcnt_op(a) when is_integer(a) do
    # Population count: number of 1 bits
    if a == 0 do
      0
    else
      unsigned = if a < 0, do: a + 0x100000000, else: a
      Integer.digits(unsigned, 2) |> Enum.count(&(&1 == 1))
    end
  end

  # Additional bitwise operations (not currently used but kept for completeness)
  @spec and_op(integer(), integer()) :: integer()
  def and_op(a, b) when is_integer(a) and is_integer(b), do: Bitwise.band(a, b)

  @spec or_op(integer(), integer()) :: integer()
  def or_op(a, b) when is_integer(a) and is_integer(b), do: Bitwise.bor(a, b)

  @spec xor_op(integer(), integer()) :: integer()
  def xor_op(a, b) when is_integer(a) and is_integer(b), do: Bitwise.bxor(a, b)

  @spec not_op(integer()) :: integer()
  def not_op(a) when is_integer(a), do: Bitwise.bnot(a)

  @spec asr_op(integer(), integer()) :: integer()
  def asr_op(a, b) when is_integer(a) and is_integer(b) and b >= 0 do
    # Arithmetic shift right (preserves sign)
    Bitwise.bsr(a, b)
  end

  @spec lsl_op(integer(), integer()) :: integer()
  def lsl_op(a, b) when is_integer(a) and is_integer(b) and b >= 0 do
    # Logical shift left
    Bitwise.bsl(a, b)
  end
end
