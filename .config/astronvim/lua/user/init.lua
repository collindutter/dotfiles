return {
    colorscheme = "catppuccin-macchiato",
    mappings = {
        n = {
            ["<leader>t"] = { name = "Test" },
            ["<leader>tn"] = {
                function()
                    require("neotest").run.run()
                end,
                desc = "Run the nearest test"
            },
            ["<leader>tc"] = {
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Run the current file"
            },
            ["<leader>td"] = {
                function()
                    require("neotest").run.run({
                        suite = false,
                        strategy = "dap"
                    })
                end,
                desc = "Debug the nearest test"
            },
            ["<leader>dt"] = {
                function()
                    require("neotest").run.run({
                        suite = false,
                        strategy = "dap"
                    })
                end,
                desc = "Debug the nearest test"
            },
            ["<leader>ts"] = {
                function()
                    require("neotest").run.stop()
                end,
                desc = "Stop the nearest test"
            },
            ["<leader>m"] = {
                function()
                    require("zen-mode").toggle({})
                end,
                desc = "Toggle zen mode"
            },
            ["<leader>xx"] = {
                function()
                    require("trouble").open()
                end
            },
            ["<leader>xw"] = {
                function()
                    require("trouble").open("workspace_diagnostics")
                end,
                desc = 'Open workspace diagnostics'
            },
            ["<leader>xd"] = {
                function()
                    require("trouble").open("document_diagnostics")
                end,
                desc = 'Open document diagnostics (Trouble)'
            },
            ["<leader>xq"] = {
                function()
                    require("trouble").open("quickfix")
                end,
                desc = 'Open quickfix (Trouble)'
            },
            ["<leader>gR"] = {
                function()
                    require("trouble").open("lsp_references")
                end,
                desc = 'Open lsp references (Trouble)'
            },
            ["[t"] = {
                function()
                    require("trouble").previous({
                        skip_groups = true,
                        jump = true
                    });
                end
            },
            ["]t"] = {
                function()
                    require("trouble").next({
                        skip_groups = true,
                        jump = true
                    });
                end
            },
            ["<leader>q"] = false
        }
    },
    polish = function()
        -- Spider
        vim.keymap.set({ "n", "o", "x" }, "w", function()
            require('spider').motion('w')
        end, { desc = "Spider-w" })
        vim.keymap.set({ "n", "o", "x" }, "e", function()
            require('spider').motion('e')
        end, { desc = "Spider-e" })
        vim.keymap.set({ "n", "o", "x" }, "b", function()
            require('spider').motion('b')
        end, { desc = "Spider-b" })
        vim.keymap.set({ "n", "o", "x" }, "ge", function()
            require('spider').motion('ge')
        end, { desc = "Spider-ge" })
        vim.keymap.set({ "n", "o", "x" }, "cw", "ce",
            { desc = "Spider-ce", remap = true })

        -- Page movement
        vim.keymap.set("n", "<C-d>", "<C-d>zz",
            {
                desc = "Center cursor after moving down half-page"
            })
        vim.keymap.set("n", "<C-u>", "<C-u>zz",
            {
                desc = "Center cursor after moving up half-page"
            })

        -- Dap UI
        vim.keymap.set('n', "<leader>du", function()
            require("dapui").toggle({ reset = true })
        end, { desc = "Toggle Debugger UI" })
    end,
    options = {
        g = {
            python3_host_prog = '~/.virtualenvs/py3nvim/bin/python',
            editorconfig = false
        },
        opt = { shell = "/bin/bash", fixeol = false }
    },
    lsp = {
        formatting = {
            timeout_ms = 15000,
            format_on_save = false
        },
        config = {
            lua_ls = {
                settings = {
                    Lua = {
                        diagnostics = {
                            -- Get the language server to recognize the `vim` global
                            globals = { 'vim' }
                        }
                    }
                }
            },
            pyright = {
                settings = {
                    python = {
                        pythonPath = ".venv/bin/python"
                    }
                }
            },
            yamlls = {
                settings = {
                    yaml = {
                        customTags = {
                            "!And scalar",
                            "!And mapping",
                            "!And sequence",
                            "!If scalar",
                            "!If mapping",
                            "!If sequence",
                            "!Not scalar",
                            "!Not mapping",
                            "!Not sequence",
                            "!Equals scalar",
                            "!Equals mapping",
                            "!Equals sequence",
                            "!Or scalar",
                            "!Or mapping",
                            "!Or sequence",
                            "!FindInMap scalar",
                            "!FindInMap mapping",
                            "!FindInMap sequence",
                            "!Base64 scalar",
                            "!Base64 mapping",
                            "!Base64 sequence",
                            "!Cidr scalar",
                            "!Cidr mapping",
                            "!Cidr sequence",
                            "!Ref scalar",
                            "!Ref mapping",
                            "!Ref sequence",
                            "!Sub scalar",
                            "!Sub mapping",
                            "!Sub sequence",
                            "!GetAtt scalar",
                            "!GetAtt mapping",
                            "!GetAtt sequence",
                            "!GetAZs scalar",
                            "!GetAZs mapping",
                            "!GetAZs sequence",
                            "!ImportValue scalar",
                            "!ImportValue mapping",
                            "!ImportValue sequence",
                            "!Select scalar",
                            "!Select mapping",
                            "!Select sequence",
                            "!Split scalar",
                            "!Split mapping",
                            "!Split sequence",
                            "!Join scalar",
                            "!Join mapping",
                            "!Join sequence"
                        }
                    }
                }
            }
        }
    },
    plugins = {
        {
            "nvim-telescope/telescope.nvim",
            config = function(plugin, opts)
                local trouble = require("trouble.providers.telescope")
                require("plugins.configs.telescope")(plugin, opts)

                require('telescope').setup({
                    defaults = {
                        mappings = {
                            i = {
                                ["<C-t>"] = trouble.open_with_trouble
                            },
                            n = {
                                ["<C-t>"] = trouble.open_with_trouble
                            }
                        }
                    }
                })
            end
        },
        {
            "mfussenegger/nvim-dap-python",
            config = function()
                require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
            end,
            event = "User AstroFile"
        },
        {
            "jose-elias-alvarez/null-ls.nvim",
            opts = function(_, config)
                local null_ls = require "null-ls"
                config.sources = {
                    null_ls.builtins.formatting.prettier.with({
                        prefer_local = 'node_modules/.bin'
                    }),
                    null_ls.builtins.formatting.eslint.with({
                        prefer_local = 'node_modules/.bin'
                    }),
                    null_ls.builtins.formatting.ruff.with({
                        prefer_local = '.venv/bin'
                    }),
                    null_ls.builtins.formatting.black.with({
                        prefer_local = '.venv/bin'
                    }),
                    null_ls.builtins.formatting.lua_format.with({
                        extra_args = {
                            "--no-keep-simple-control-block-one-line",
                            "--no-keep-simple-function-one-line",
                            "--no-align-table-field",
                            "--no-align-args",
                            "--no-align-parameter",
                            "--spaces-inside-table-braces",
                            "--chop-down-table",
                            "--column-table-limit=60"
                        }
                    })
                }
                return config
            end
        },
        {
            "williamboman/mason-lspconfig.nvim",
            opts = {
                ensure_installed = {
                    "tsserver",
                    'ruff_lsp',
                    'lua_ls',
                    'pyright',
                    'jsonls'
                }
            }
        },
        {
            "jay-babu/mason-null-ls.nvim",
            opts = {
                ensure_installed = {
                    'ruff',
                    'black',
                    'eslint',
                    'prettier',
                    'lua_format',
                    'codespell'
                }
            }
        },
        {
            "nvim-treesitter/nvim-treesitter",
            opts = { ensure_installed = "all" }
        },
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
        },
        {
            "hrsh7th/nvim-cmp",
            dependencies = { "zbirenbaum/copilot.lua" },
            opts = function(_, opts)
                local cmp, copilot = require "cmp", require "copilot.suggestion"
                local snip_status_ok, luasnip = pcall(require, "luasnip")
                if not snip_status_ok then
                    return
                end
                local function has_words_before()
                    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                    return col ~= 0 and
                               vim.api
                                   .nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(
                            col, col):match "%s" == nil
                end
                if not opts.mapping then
                    opts.mapping = {}
                end
                opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
                    if copilot.is_visible() then
                        copilot.accept()
                    elseif cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fallback()
                    end
                end, { "i", "s" })

                opts.mapping["<C-c>"] = cmp.mapping(function()
                    if copilot.is_visible() then
                        copilot.dismiss()
                    end
                end)

                return opts
            end
        },
        {
            "zbirenbaum/copilot.lua",
            cmd = "Copilot",
            event = "User AstroFile",
            opts = {
                panel = { enabled = false },
                suggestion = {
                    auto_trigger = true,
                    debounce = 150
                },
                filetypes = { yaml = true }
            }
        },
        {
            "rcarriga/nvim-dap-ui",
            config = function(plugin, opts)
                require "plugins.configs.nvim-dap-ui"(plugin, opts)

                local dap = require("dap")
                dap.listeners.before.event_terminated["dapui_config"] = nil
                dap.listeners.before.event_exited["dapui_config"] = nil
            end,
            opts = {

                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.25 },
                            {
                                id = "breakpoints",
                                size = 0.25
                            },
                            { id = "stacks", size = 0.25 },
                            { id = "watches", size = 0.25 }
                        },
                        position = "left",
                        size = 40
                    }
                }
            }
        },
        {
            "nvim-neotest/neotest",
            ft = { "python" },
            dependencies = {
                "nvim-neotest/neotest-python",
                {
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
                        require("neotest-python")({
                            dap = { justMyCode = false }
                        })
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
                                    " "):gsub("%s+", " "):gsub("^%s+", "")
                            return message
                        end
                    }
                }, neotest_ns)
                require("neotest").setup(opts)
            end
        },
        {
            "folke/zen-mode.nvim",
            opts = {},
            event = "User AstroFile"
        },
        {
            "folke/flash.nvim",
            event = "VeryLazy",
            opts = {
                modes = { search = { enabled = false } }
            },
            keys = {
                {
                    "s",
                    mode = { "n", "x", "o" },
                    function()
                        require("flash").jump()
                    end,
                    desc = "Flash"
                },
                {
                    "S",
                    mode = { "n", "o", "x" },
                    function()
                        require("flash").treesitter()
                    end,
                    desc = "Flash Treesitter"
                }
            }
        },
        {
            "m4xshen/hardtime.nvim",
            enabled=false,
            opts = {
                disabled_filetypes = {
                    "lazy",
                    "mason",
                    "neo-tree",
                    "neo-tree-popup",
                    "dapui_breakpoints",
                    "dapui_scopes",
                    "dapui_stacks",
                    "dapui_watches",
                    "dapui_console",
                    "dap-repl",
                    "dap-float",
                    "alpha",
                    "vim",
                    "qf",
                    "dressinginput",
                    "TelescopePrompt",
                    "trouble",
                    "help",
                    "spectre_panel"

                }
            },
            lazy = false
        },
        {
            "chrisgrieser/nvim-spider",
            event = "User AstroFile",
            opts = { skipInsignificantPunctuation = false }
        },
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000
        },
        {
            'goolord/alpha-nvim',
            opts = function()
                local dashboard = require "alpha.themes.dashboard"

                dashboard.section.header.val = {
                    "                                                     ",
                    "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
                    "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
                    "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
                    "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
                    "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
                    "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
                    "                                                     "
                }

                local button = require("astronvim.utils").alpha_button
                dashboard.section.buttons.val = {
                    button("LDR n", "  New File  "),
                    button("LDR f f", "  Find File  "),
                    button("LDR f o", "󰈙  Find Old File  "),
                    button("LDR f w", "󰈭  Find Word  ")
                }

                dashboard.section.footer.val = {}

                return dashboard
            end,
            config = function(_, opts)
                require("alpha").setup(opts.config)
            end

        },
        {
            "folke/trouble.nvim",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            opts = {}
        },
        {
            "kylechui/nvim-surround",
            version = "*", -- Use for stability; omit to use `main` branch for the latest features
            event = "VeryLazy",
            opts = {}
        },
        { "Shatur/neovim-session-manager", enabled = false },
        { "akinsho/toggleterm.nvim", enabled = false },
        {
            "nvim-pack/nvim-spectre",
            cmd = "Spectre",
            keys = {
                {
                    "<leader>fr",
                    function()
                        require("spectre").toggle()
                    end,
                    desc = "Find and replace"
                }
            },
            event = "User AstroFile"
        },
        {
            "stevearc/oil.nvim",
            opts = {
                keymaps = {
                    ["<C-l>"] = false,
                    ["<C-h>"] = false
                }
            },
            keys = {
                {
                    "-",
                    "<cmd>Oil<cr>",
                    mode = "n",
                    desc = "Open Oil"
                }
            }
        }
    }
}
