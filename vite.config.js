import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
  ],
  resolve: {
    alias: {
      // This tells Vite to use the version of Vue that can 
      // compile templates in the browser (needed for Rails views)
      'vue': 'vue/dist/vue.esm-bundler.js'
    }
  }
})