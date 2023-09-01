return {
    colorscheme = "tokyonight",
    mappings = {
        n = {
            ["<leader>T"] = {name = "Test"},
            ["<leader>Tn"] = {
                '<cmd>lua require("neotest").run.run()<cr>',
                desc = "Run the nearest test"
            },
            ["<leader>Tc"] = {
                '<cmd>lua require("neotest").run.run(vim.fn.expand("%"))<cr>',
                desc = "Run the current file"
            },
            ["<leader>Td"] = {
                '<cmd>lua require("neotest").run.run({strategy = "dap"})<cr>',
                desc = "Debug the nearest test"
            },
            ["<leader>dt"] = {
                '<cmd>lua require("neotest").run.run({strategy = "dap"})<cr>',
                desc = "Debug the nearest test"
            },
            ["<leader>Ts"] = {
                '<cmd>lua require("neotest").run.stop()<cr>',
                desc = "Stop the nearest test"
            },
            ["<leader>fp"] = {
                function()
                    require("telescope.builtin").find_files {
                        search_dirs = {"../"}
                    }
                end,
                desc = "Find parent files"
            },
            ["<leader>m"] = {
                function() require("zen-mode").toggle({}) end,
                desc = "Toggle zen mode"
            }
        }
    },
    polish = function()
        vim.keymap.set({"n", "o", "x"}, "w",
                       "<cmd>lua require('spider').motion('w')<CR>",
                       {desc = "Spider-w"})
        vim.keymap.set({"n", "o", "x"}, "e",
                       "<cmd>lua require('spider').motion('e')<CR>",
                       {desc = "Spider-e"})
        vim.keymap.set({"n", "o", "x"}, "b",
                       "<cmd>lua require('spider').motion('b')<CR>",
                       {desc = "Spider-b"})
        vim.keymap.set({"n", "o", "x"}, "ge",
                       "<cmd>lua require('spider').motion('ge')<CR>",
                       {desc = "Spider-ge"})
    end,
    options = {
        g = {
            copilot_no_tab_map = true,
            copilot_assume_mapped = true,
            copilot_tab_fallback = "",
            python3_host_prog = '~/.virtualenvs/py3nvim/bin/python',
            editorconfig = false
        },
        opt = {shell = "/bin/bash"}
    },
    lsp = {
        formatting = {timeout_ms = 15000, format_on_save = false},
        config = {
            lua_ls = {
                settings = {
                    Lua = {
                        diagnostics = {
                            -- Get the language server to recognize the `vim` global
                            globals = {'vim'}
                        }
                    }
                }
            },
            yamlls = {
                settings = {
                    yaml = {
                        customTags = {
                            "!And scalar", "!And mapping", "!And sequence",
                            "!If scalar", "!If mapping", "!If sequence",
                            "!Not scalar", "!Not mapping", "!Not sequence",
                            "!Equals scalar", "!Equals mapping",
                            "!Equals sequence", "!Or scalar", "!Or mapping",
                            "!Or sequence", "!FindInMap scalar",
                            "!FindInMap mappping", "!FindInMap sequence",
                            "!Base64 scalar", "!Base64 mapping",
                            "!Base64 sequence", "!Cidr scalar", "!Cidr mapping",
                            "!Cidr sequence", "!Ref scalar", "!Ref mapping",
                            "!Ref sequence", "!Sub scalar", "!Sub mapping",
                            "!Sub sequence", "!GetAtt scalar",
                            "!GetAtt mapping", "!GetAtt sequence",
                            "!GetAZs scalar", "!GetAZs mapping",
                            "!GetAZs sequence", "!ImportValue scalar",
                            "!ImportValue mapping", "!ImportValue sequence",
                            "!Select scalar", "!Select mapping",
                            "!Select sequence", "!Split scalar",
                            "!Split mapping", "!Split sequence", "!Join scalar",
                            "!Join mapping", "!Join sequence"
                        }
                    }
                }
            }
        }
    },
    plugins = {
        {
            "mfussenegger/nvim-dap-python",
            config = function()
                require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
            end,
            event = "User AstroFile"
        }, {
            "jose-elias-alvarez/null-ls.nvim",
            opts = function(_, config)
                local null_ls = require "null-ls"
                config.sources = {
                    null_ls.builtins.formatting.prettier.with({
                        only_local = 'node_modules/.bin'
                    }),
                    null_ls.builtins.formatting.eslint
                        .with({only_local = 'node_modules/.bin'}),
                    null_ls.builtins.formatting.ruff
                        .with({only_local = '.venv/bin'}),
                    null_ls.builtins.formatting.black
                        .with({prefer_local = '.venv/bin'})
                }
                return config
            end
        }, {
            "williamboman/mason-lspconfig.nvim",
            opts = {ensure_installed = {"tsserver", 'ruff_lsp', 'lua_ls'}}
        },
        {"nvim-treesitter/nvim-treesitter", opts = {ensure_installed = "all"}},
        {
            'alexghergh/nvim-tmux-navigation',
            config = function()
                require('nvim-tmux-navigation').setup {
                    disable_when_zoomed = true,
                    keybindings = {
                        left = "<C-h>",
                        down = "<C-j>",
                        up = "<C-k>",
                        right = "<C-l>",
                        last_active = "<C-\\>",
                        next = "<C-Space>"
                    }
                }
            end,
            lazy = false
        }, {
            "hrsh7th/nvim-cmp",
            opts = function(_, opts)
                local cmp = require "cmp"
                opts.mapping["<C-e>"] = function(fallback)
                    cmp.mapping.abort()
                    local copilot_keys = vim.fn["copilot#Accept"]()
                    if copilot_keys ~= "" then
                        vim.api.nvim_feedkeys(copilot_keys, "i", true)
                    else
                        fallback()
                    end
                end

                return opts
            end
        }, {"github/copilot.vim", event = "User AstroFile"}, {
            "rcarriga/nvim-dap-ui",
            config = function(plugin, opts)
                require "plugins.configs.nvim-dap-ui"(plugin, opts)

                -- disable dap events that are created
                local dap, dapui = require("dap"), require("dapui")
                dap.listeners.before.event_terminated["dapui_config"] = nil
                dap.listeners.before.event_exited["dapui_config"] = nil
            end
        }, {
            "nvim-neotest/neotest",
            ft = {"python"},
            dependencies = {
                "nvim-neotest/neotest-python", {
                    "folke/neodev.nvim",
                    opts = function(_, opts)
                        opts.library = opts.library or {}
                        if opts.library.plugins ~= true then
                            opts.library.plugins =
                                require("astronvim.utils").list_insert_unique(
                                    opts.library.plugins, "neotest")
                        end
                        opts.library.types = true
                    end
                }
            },
            opts = function()
                return {
                    adapters = {
                        require("neotest-python")({dap = {justMyCode = false}})
                    }
                }
            end,
            config = function(_, opts)
                local neotest_ns = vim.api.nvim_create_namespace "neotest"
                vim.diagnostic.config({
                    virtual_text = {
                        format = function(diagnostic)
                            local message =
                                diagnostic.message:gsub("\n", " "):gsub("\t",
                                                                        " ")
                                    :gsub("%s+", " "):gsub("^%s+", "")
                            return message
                        end
                    }
                }, neotest_ns)
                require("neotest").setup(opts)
            end
        }, {"folke/zen-mode.nvim", opts = {}, lazy = false}, {
            "folke/flash.nvim",
            event = "VeryLazy",
            ---@type Flash.Config
            opts = {},
            keys = {
                {
                    "s",
                    mode = {"n", "x", "o"},
                    function() require("flash").jump() end,
                    desc = "Flash"
                }, {
                    "S",
                    mode = {"n", "o", "x"},
                    function() require("flash").treesitter() end,
                    desc = "Flash Treesitter"
                }
            }
        }, {
            "m4xshen/hardtime.nvim",
            opts = {
                disabled_filetypes = {
                    "lazy", "mason", "neo-tree", "neo-tree-popup",
                    "dapui_breakpoints", "dapui_scopes", "dapui_stacks",
                    "dapui_watches", "dap-repl", "dapui_console", "alpha",
                    "vim", "qf", "dressinginput"
                }
            },
            lazy = false
        },
        {
            "folke/tokyonight.nvim",
            name = "tokyonight",
            priority = 1000,
            lazy = false
        }, {"chrisgrieser/nvim-spider", lazy = false}
    }
}
