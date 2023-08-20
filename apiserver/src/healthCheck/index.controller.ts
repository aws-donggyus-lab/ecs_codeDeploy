import dayjs from 'dayjs'
import { Request, Response, Router } from 'express'
import { reqMiddleware } from '../middlewares/reqMiddleware'
class HealthCheckController {
  router: Router

  constructor() {
    this.router = Router()
    this.router.get('/health', reqMiddleware, this.healthCheck)
    this.router.get('/env', reqMiddleware, this.outputEnv)
  }

  healthCheck(req: Request, res: Response) {
    console.log('success ===> new version 1.0')
    return res.status(200).json('success')
  }

  outputEnv(req: Request, res: Response) {
    console.log(dayjs().format('YYYY-MM-DD HH:mm:ss'))
    console.log({
      port: process.env.PORT,
      name: process.env.NAME,
      age: process.env.AGE,
      per: process.env.PER,
    })
  }
}

export const healthCheckController = new HealthCheckController()
