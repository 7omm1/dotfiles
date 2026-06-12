-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- buffers
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- No more navigation using arrow keys
for _, mode in ipairs { "n", "v" } do
  for _, key in ipairs { "<Up>", "<Down>", "<Left>", "<Right>" } do
    map(mode, key, "<nop>")
  end
end

-- Remove trailing spaces
map("n", "<leader>rs", function()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd [[%s/\s\+$//e]]
  vim.api.nvim_win_set_cursor(0, cursor_pos)
  vim.cmd "nohlsearch"
end, { desc = "Remove trailing spaces" })

-- ==========================================
-- Compilar y Ejecutar C++ con F5
-- Compatible con Linux y Windows
-- ==========================================
vim.keymap.set("n", "<F5>", function()
  vim.cmd "w"

  local file = vim.fn.expand "%:p"
  local out = vim.fn.expand "%:p:r"
  local filename = vim.fn.expand "%:t"
  local is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1

  local cmd

  if is_windows then
    -- En Windows el ejecutable lleva .exe y usamos cmd.exe
    local out_exe = out .. ".exe"
    cmd = string.format(
      'cmd /c "g++ -g "%s" -o "%s" 2>&1 && echo. && echo --- Programa terminado. Presiona ENTER para cerrar --- && "%s" & pause"',
      file,
      out_exe,
      out_exe
    )
  else
    -- Linux / macOS
    cmd = string.format(
      [[
      clear
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo " Compilando: %s"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      ERRORES=$(g++ -g "%s" -o "%s" 2>&1)
      EXITCODE=$?

      if [ $EXITCODE -ne 0 ]; then
        echo ""
        echo "✗ Error de compilación:"
        echo "─────────────────────────────────────────────"
        echo "$ERRORES" | sed 's/.*error:/❌ error:/g' | sed 's/.*warning:/⚠️  warning:/g'
        echo "─────────────────────────────────────────────"
        echo ""
      else
        echo " Compilación exitosa — ejecutando...\n"
        echo "─────────────────────────────────────────────"
        echo ""

        START_NS=$(date +%%s%%N)
        "%s"
        EXITRUN=$?
        END_NS=$(date +%%s%%N)
        ELAPSED=$(( (END_NS - START_NS) / 1000000 ))

        echo ""
        echo "─────────────────────────────────────────────"
        if [ $EXITRUN -eq 0 ]; then
          echo " Programa terminado correctamente"
        else
          echo "⚠️  Terminó con código de error: $EXITRUN"
        fi
        echo "⏱  Tiempo de ejecución: ${ELAPSED}ms"
        echo "─────────────────────────────────────────────"
      fi
      echo ""
      echo "Presiona ENTER para cerrar..."
      read _
    ]],
      filename,
      file,
      out,
      out
    )
  end

  Snacks.terminal(cmd, {
    win = {
      position = "right",
      width = 0.4,
      winblend = 15,
    },
  })
end, { desc = "Compilar y Ejecutar C++" })
