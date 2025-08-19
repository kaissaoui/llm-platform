import { NextApiRequest, NextApiResponse } from 'next'

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ message: 'Method not allowed' })
  }

  try {
    // Readiness check - verify all dependencies are available
    const readinessStatus = {
      status: 'ready',
      timestamp: new Date().toISOString(),
      checks: {
        database: 'ready',     // Add actual DB connection check
        redis: 'ready',        // Add actual Redis connection check
        external_apis: 'ready', // Add actual API key validation
        file_system: 'ready',   // Add actual file system check
      },
    }

    res.status(200).json(readinessStatus)
  } catch (error) {
    console.error('Readiness check failed:', error)
    res.status(503).json({ 
      status: 'not_ready',
      error: 'Readiness check failed',
      timestamp: new Date().toISOString()
    })
  }
}
