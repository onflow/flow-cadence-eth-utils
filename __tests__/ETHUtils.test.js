import path from "path"
import {
  init,
  emulator,
  getAccountAddress,
  deployContractByName
} from "@onflow/flow-js-testing"

describe("ETHUtils test suite", () => {

  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    await init(basePath);
    await emulator.start(false);
    return new Promise((resolve) => setTimeout(resolve, 1000));
  });

  afterEach(async () => {
    await emulator.stop();
    return new Promise((resolve) => setTimeout(resolve, 1000));
  });

  test("ExampleNFT Test Suite", async () => {
    const admin = await getAccountAddress("Admin");
    const [result, error] = await deployContractByName({ to: admin, name: "ETHUtils" });
    expect(result).not.toBe(null);
    expect(error).toBe(null)
  })
})