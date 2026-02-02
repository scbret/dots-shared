return {
  'vimwiki/vimwiki',
  init = function()
    -- Enable syntax highlighting globally
    vim.g.vimwiki_global_ext = 0
    
    -- Configure the wiki path and syntax
    vim.g.vimwiki_list = {
      {
        path = '~/repos/vimwiki/',
        syntax = 'markdown',
        ext = '.md',
      }
    }
  end,
}
