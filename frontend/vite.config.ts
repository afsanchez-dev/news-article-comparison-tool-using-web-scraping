import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import EnvironmentPlugin from 'vite-plugin-environment'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react(), EnvironmentPlugin(['SCRAPER_URL', 'COMPARE_API_TOKEN', 'COMPARE_API_URL'])],
})
