import { ErrorType } from '../../types'

/**
 * Returns an error string
 * @param {ErrorType} error
 * @returns {string}
 */
export const getError = (error: ErrorType): string => {
    switch (error) {
        case ErrorType.EmptyTopicError:
            return 'empty-topic-error'

        case ErrorType.FetchError:
            return 'fetch-error'

        default:
            return 'unknown-error'
    }
}
