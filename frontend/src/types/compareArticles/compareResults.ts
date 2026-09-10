/**
 * Represents a successful response from the compare API
 * @interface compareQuery
 */
export interface successCompareResult {
    /**
     * Processing time in miliseconds
     * @type {number}
     */
    time: number
    /**
     * Similarity ratio
     * @type {number}
     */
    similarity: number
    /**
     * Processing language
     * @type {string}
     */
    lang: string
    /**
     * Current time of the response
     * @type {string}
     */
    timestamp: string
}

/**
 * Represents an error response from the compare API
 * @interface errorCompareResult
 */
export interface errorCompareResult {
    /**
     * Error message
     * @type {string}
     */
    message: string
    /**
     * Code of the error
     * @type {string}
     */
    code: string
    /**
     * Error information
     * @type {Record<string, string>}
     */
    data: Record<string, string>
    /**
     * Boolean indicating if the response has errors
     * @type {boolean}
     */
    error: boolean
}

/**
 * Represents a response from the compare API
 * @type compareResult
 */
export type compareResult = successCompareResult | errorCompareResult
