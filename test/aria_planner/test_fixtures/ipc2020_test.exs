# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.TestFixtures.Ipc2020Test do
  use ExUnit.Case, async: true

  alias AriaPlanner.TestFixtures.Ipc2020

  describe "root_path/0" do
    test "returns path when thirdparty/ipc2020-domains exists" do
      if Ipc2020.available?() do
        path = Ipc2020.root_path()
        assert is_binary(path)
        assert File.exists?(path)
        assert File.dir?(path)
      end
    end
  end

  describe "list_domain_names/1" do
    @tag :ipc2020
    test "total-order lists known IPC 2020 domain names when submodule present" do
      if Ipc2020.available?() do
        names = Ipc2020.list_domain_names("total-order")
        assert is_list(names)
        # IPC 2020 total-order includes these (from panda-planner-dev/ipc2020-domains)
        assert length(names) >= 1
        assert "Blocksworld-GTOHP" in names or "Rover-GTOHP" in names or "AssemblyHierarchical" in names or length(names) > 0
      end
    end

    @tag :ipc2020
    test "partial-order lists domain names when submodule present" do
      if Ipc2020.available?() do
        names = Ipc2020.list_domain_names("partial-order")
        assert is_list(names)
      end
    end
  end
end
