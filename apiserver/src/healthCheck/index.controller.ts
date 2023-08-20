import dayjs from 'dayjs'
import { Request, Response, Router } from 'express'
import { reqMiddleware } from '../middlewares/reqMiddleware'
class HealthCheckController {
  router: Router

  constructor() {
    this.router = Router()
    this.router.get('/health', reqMiddleware, this.healthCheck)
  }

  async healthCheck(req: Request, res: Response) {
    return res.status(200).json({
      version: process.env.VERSION,
      date: dayjs().format('YYYY-MM-DD HH:mm:ss'),
      port: process.env.PORT,
      name: process.env.NAME,
      age: process.env.AGE,
      per: process.env.PER,
    })
  }
}

export const healthCheckController = new HealthCheckController()
