import nock from 'nock'
import { type GetArticleResult } from '../../../../src/types'
const baseUrl = process.env.SCRAPER_URL ?? ''

export function getArticleMock(index: number): GetArticleResult {
    return {
        newspaper: 'Test Newspaper ' + index,
        headline: 'Test Headline ' + index,
        subheadline: 'Test Subheadline' + index,
        authors: [
            {
                name: 'Test Author ' + index,
                url: 'testauthorturl' + index,
            },
        ],
        last_date_time: '2023-10-30T15:31:48Z',
        body: [{ p: 'Test body ' + index }],
        url: 'testurl' + index,
    }
}
const errorResult = {
    error: 'test error',
}
const baseServer = nock(baseUrl).get(/.*/)

const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST',
}

export const setupSuccess = (): void => {
    baseServer
        .reply(200, getArticleMock(0), headers)
        .get(/.*/)
        .reply(200, getArticleMock(1), headers)
        .get(/.*/)
        .reply(200, getArticleMock(2), headers)
}

export const setupErrorResult = (): void => {
    baseServer.reply(400, errorResult, headers)
}
