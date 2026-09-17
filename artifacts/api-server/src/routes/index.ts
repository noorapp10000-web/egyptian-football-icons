import { Router, type IRouter } from "express";
import healthRouter from "./health";
import userRouter from "./user";
import footballRouter from "./football";

const router: IRouter = Router();

router.use(healthRouter);
router.use(userRouter);
router.use(footballRouter);

export default router;
