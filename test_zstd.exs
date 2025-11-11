# Temporary test script to verify :zstd module
IO.puts("OTP Version: #{:erlang.system_info(:otp_release)}")

try do
  test_data = "Hello, World!"
  compressed = :zstd.compress(test_data)
  compressed_binary = IO.iodata_to_binary(compressed)
  decompressed = :zstd.decompress(compressed_binary)
  decompressed_binary = IO.iodata_to_binary(decompressed)
  
  if decompressed_binary == test_data do
    IO.puts("SUCCESS: :zstd module is available and working")
    IO.puts("  - Compression: OK")
    IO.puts("  - Decompression: OK")
    IO.puts("  - Round-trip: OK")
  else
    IO.puts("ERROR: Round-trip failed")
    IO.puts("  Original: #{inspect(test_data)}")
    IO.puts("  Decompressed: #{inspect(decompressed_binary)}")
  end
  
  # Test with compression options (check if compression_level is valid)
  try do
    compressed2 = :zstd.compress(test_data, %{compression_level: 1})
    compressed2_binary = IO.iodata_to_binary(compressed2)
    decompressed2 = :zstd.decompress(compressed2_binary)
    decompressed2_binary = IO.iodata_to_binary(decompressed2)
    
    if decompressed2_binary == test_data do
      IO.puts("  - Compression with options: OK")
    else
      IO.puts("  - Compression with options: Round-trip failed")
    end
  rescue
    e ->
      IO.puts("  - Compression with options: #{inspect(e)} (may not be supported)")
  end
rescue
  e ->
    IO.puts("ERROR: #{inspect(e)}")
    System.halt(1)
end

