
# gmod-globals-scraper

This small script scrapes the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Main_Page) for global variables and functions for use in [luacheck](https://github.com/impulsh/gluacheck). It isn't a fully automated process - you'll have to add and/or remove a few globals depending on your use case.

## Usage

This isn't a proper CLI tool, so you'll have to bear with editing the script itself. Most things are self-explanatory and shouldn't need changing anyway. You'll need [LuaRocks](https://github.com/luarocks/luarocks) and a couple of packages to get it working. However, installing them is simple enough:

```
luarocks install http
luarocks install htmlparser
lua script.lua
```

It will start scraping the wiki and dump the contents into `globals.txt` by default.
