/**
 * Represents the query for comparing two articles
 * @interface compareQuery
 */
export interface compareQuery {
    /**
     * The first article
     * @type {string}
     */
    text1: string
    /**
     * The second article
     * @type {string}
     */
    text2: string
}
