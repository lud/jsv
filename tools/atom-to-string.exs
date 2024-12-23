Code.append_path("_build/dev/lib/jsv/ebin")

Mix.install([:benchee])
alias JSV.AtomTools

small_map = fn term ->
  %{
    "sub" => [
      "some big gar bage",
      "with a",
      ~c"long list of",
      term
    ],
    "a" => term
  }
end

big_map = fn term ->
  %{
    "a" => %{
      "sub" => ["some big gar bage", "with a", ~c"long list of", term],
      "a" => %{
        "sub" => ["some big gar bage", "with a", ~c"long list of", term],
        "a" => %{
          "sub" => ["some big gar bage", "with a", ~c"long list of", term],
          "a" => %{
            "sub" => ["some big gar bage", "with a", ~c"long list of", term],
            "a" => %{
              "sub" => ["some big gar bage", "with a", ~c"long list of", term],
              "a" => %{
                "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                "a" => %{
                  "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                  "a" => %{
                    "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                    "a" => %{
                      "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                      "a" => %{
                        "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                        "a" => %{
                          "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                          "a" => %{
                            "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                            "a" => %{
                              "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                              "a" => %{
                                "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                "a" => %{
                                  "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                  "a" => %{
                                    "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                    "a" => %{
                                      "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                      "a" => %{
                                        "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                        "a" => %{
                                          "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                          "a" => %{
                                            "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                            "a" => %{
                                              "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                              "a" => %{
                                                "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                                "a" => %{
                                                  "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                                  "a" => %{
                                                    "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                                    "a" => %{
                                                      "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                                      "a" => %{
                                                        "sub" => ["some big gar bage", "with a", ~c"long list of", term],
                                                        "a" => %{
                                                          "sub" => [
                                                            "some big gar bage",
                                                            "with a",
                                                            ~c"long list of",
                                                            term
                                                          ],
                                                          "a" => %{
                                                            "sub" => [
                                                              "some big gar bage",
                                                              "with a",
                                                              ~c"long list of",
                                                              term
                                                            ],
                                                            "a" => %{
                                                              "sub" => [
                                                                "some big gar bage",
                                                                "with a",
                                                                ~c"long list of",
                                                                term
                                                              ],
                                                              "a" => %{
                                                                "sub" => [
                                                                  "some big gar bage",
                                                                  "with a",
                                                                  ~c"long list of",
                                                                  term
                                                                ],
                                                                "a" => term
                                                              }
                                                            }
                                                          }
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
end

Benchee.run(
  %{
    "direct_convert" => fn input ->
      _converted = AtomTools.deatom(input)

      # precheck
      # false = AtomTools.atom_props?(converted)
    end,
    "check_before" => fn input ->
      _converted =
        if AtomTools.atom_props?(input) do
          AtomTools.deatom(input)
        else
          input
        end

      # precheck
      # false = AtomTools.atom_props?(converted)
    end
  },
  pre_check: true,
  inputs: %{
    "big_map_no_atom" => big_map.("hello"),
    "big_map_atom" => big_map.(:hello),
    "small_map_no_atom" => small_map.("hello"),
    "small_map_atom" => small_map.(:hello)
  }
)
