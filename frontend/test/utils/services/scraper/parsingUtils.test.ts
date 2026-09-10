import { parseDateTime } from '../../../../src/utils'

describe('parseDateTime', () => {
    test('Works as expected', () => {
        const ISOdate = '2023-12-13T14:05:00+01:00'
        const parsedDate = new Date(ISOdate)

        expect(parsedDate.toLocaleString()).toStrictEqual(parseDateTime(ISOdate))
    })
})
