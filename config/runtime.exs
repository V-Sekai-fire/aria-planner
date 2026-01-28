# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# This file is responsible for configuring your application
# at runtime. It is loaded after compilation and before the
# application starts.

import Config

# Load .env file if it exists (for local development)
# In production, use system environment variables or secrets management
if File.exists?(".env") do
  File.stream!(".env")
  |> Stream.filter(fn line ->
    line = String.trim(line)
    String.length(line) > 0 and not String.starts_with?(line, "#")
  end)
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        key = String.trim(key)
        value = String.trim(value) |> String.replace(~r/^["']|["']$/, "")
        System.put_env(key, value)

      _ ->
        :ok
    end
  end)
end

# Database configuration from environment variables
# Only applies in production (dev and test use their own config files)
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      "postgres://#{System.get_env("DB_USERNAME", "postgres")}:#{System.get_env("DB_PASSWORD", "")}@#{System.get_env("DB_HOSTNAME", "localhost")}:#{System.get_env("DB_PORT", "5432")}/#{System.get_env("DB_NAME", "postgres")}"

  config :aria_planner, AriaPlanner.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
    ssl: System.get_env("DB_SSL", "false") == "true",
    ssl_opts: [
      verify: :verify_none
    ]
end
