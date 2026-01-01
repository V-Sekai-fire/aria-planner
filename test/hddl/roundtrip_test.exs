# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlanner.HDDL.RoundtripTest do
  use ExUnit.Case

  alias AriaCore.PlanningDomain
  alias AriaPlanner.HDDL

  test "roundtrip: import domain then export" do
    path = "test/fixtures/hddl/fox_geese_corn.hddl"

    # Import
    assert {:ok, %PlanningDomain{} = domain} = HDDL.import_from_file(path)

    # Export
    exported_hddl = HDDL.export_to_string(domain)

    # Verify exported HDDL contains key elements
    assert String.contains?(exported_hddl, "define (domain")
    assert String.contains?(exported_hddl, ":requirements")
    assert String.contains?(exported_hddl, ":aria-domain-metadata")

    # Re-import exported HDDL
    assert {:ok, %PlanningDomain{} = reimported_domain} = HDDL.import_from_string(exported_hddl)

    # Verify key properties are preserved
    assert reimported_domain.domain_type == domain.domain_type
    assert reimported_domain.name == domain.name
    assert reimported_domain.version == domain.version
  end

  test "roundtrip: simple domain" do
    hddl = """
    (define (domain test)
      (:requirements :strips)
      (:aria-domain-metadata
        :name "Test Domain"
        :domain-type navigation
        :version 1
      )
    )
    """

    # Import
    assert {:ok, %PlanningDomain{} = domain} = HDDL.import_from_string(hddl)

    # Export
    exported_hddl = HDDL.export_to_string(domain)

    # Re-import
    assert {:ok, %PlanningDomain{} = reimported_domain} = HDDL.import_from_string(exported_hddl)

    # Verify properties
    assert reimported_domain.name == "Test Domain"
    assert reimported_domain.domain_type == "navigation"
    assert reimported_domain.version == 1
  end
end
