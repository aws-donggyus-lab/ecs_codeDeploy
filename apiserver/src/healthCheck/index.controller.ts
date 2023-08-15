import { Request, Response, Router } from 'express'
import { reqMiddleware } from '../middlewares/reqMiddleware'
class HealthCheckController {
  router: Router

  constructor() {
    this.router = Router()
    this.router.get('/health', reqMiddleware, this.healthCheck)
  }

  healthCheck(req: Request, res: Response) {
    console.log('success ===> new version 1.0')
    return res.status(200).json('success')
  }
}

export const healthCheckController = new HealthCheckController()
