import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import translationEN from './locales/en/translation.json'
import translationES from './locales/es/translation.json'

const resources = {
    en: {
        translation: translationEN,
    },
    es: {
        translation: translationES,
    },
}

// eslint-disable-next-line @typescript-eslint/no-floating-promises
i18n.use(initReactI18next)
    .use(LanguageDetector)
    .init({
        resources,
        fallbackLng: 'en',
        interpolation: {
            escapeValue: false,
        },
        detection: {
            order: ['navigator'],
            caches: ['cookies'],
        },
    })

export default i18n
