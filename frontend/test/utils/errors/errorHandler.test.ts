import { getError } from '../../../src/utils'
import { ErrorType } from '../../../src/types'

describe('errorHandler test', () => {
    test('Works as expected', () => {
        const emptyTopicError = getError(ErrorType.EmptyTopicError)
        const fetchError = getError(ErrorType.FetchError)

        expect(emptyTopicError).toStrictEqual('empty-topic-error')
        expect(fetchError).toStrictEqual('fetch-error')
    })
})
