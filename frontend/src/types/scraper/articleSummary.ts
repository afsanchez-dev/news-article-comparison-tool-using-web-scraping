import type { Author } from './author'

/**
 * Represents the summary of an article
 * @interface ArticleSummary
 */
export interface ArticleSummary {
    /**
     * The newspaper name
     * @type {string}
     */
    newspaper: string
    /**
     * The article's authors
     * @type {Author[]}
     */
    authors?: Author[]
    /**
     * The article's title
     * @type {string}
     */
    title: string
    /**
     * The article's excerpt
     * @type {string}
     */
    excerpt: string
    /**
     * The article's date and time in locale format
     * @type {string}
     */
    date_time: string
    /**
     * The article's url
     * @type {string}
     */
    url: string
    /**
     * Indicates whether the article is premium or not
     * @type {string}
     */
    is_premium: boolean
}
