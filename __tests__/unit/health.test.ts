import { createMocks } from 'node-mocks-http'
import healthHandler from '../../src/pages/api/health'

describe('/api/health', () => {
  it('returns 200 and health status for GET request', async () => {
    const { req, res } = createMocks({
      method: 'GET',
    })

    await healthHandler(req, res)

    expect(res._getStatusCode()).toBe(200)
    
    const data = JSON.parse(res._getData())
    expect(data.status).toBe('healthy')
    expect(data.timestamp).toBeDefined()
    expect(data.uptime).toBeDefined()
    expect(data.environment).toBeDefined()
    expect(data.checks).toBeDefined()
  })

  it('returns 405 for non-GET requests', async () => {
    const { req, res } = createMocks({
      method: 'POST',
    })

    await healthHandler(req, res)

    expect(res._getStatusCode()).toBe(405)
    
    const data = JSON.parse(res._getData())
    expect(data.message).toBe('Method not allowed')
  })
})
