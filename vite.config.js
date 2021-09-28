import VitePluginHtmlEnv from 'vite-plugin-html-env'
import { resolve } from 'path'
import fs from 'fs'

var ignorePaths = [/^\.\/node_modules/, /^\.\/dist/]
var walk = function(dir) {
    var results = [];
    var list = fs.readdirSync(dir);
    list.forEach(function(file) {

        file = dir + '/' + file;
        if(ignorePaths.some(ip => file.match(ip)))
          return
        var stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            /* Recurse into a subdirectory */
            results = results.concat(walk(file));
        } else if(file.match(/\.html$/)) {
            /* Is a file */
            results.push(file);
        }
    });
    return results;
}

export default {
  plugins: [
    VitePluginHtmlEnv(),
  ],
  build: {
    rollupOptions: {
      input: walk('.').reduce((agg, entry) => ({[entry.split("/").slice(1).join("/")]: resolve(__dirname, entry), ...agg}), {})
    }
  }
}

