import {Felt, FeltLibrary} from "../src/types/Felt.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestFeltLibrary is Test {
    using FeltLibrary for uint256;

    function setup() public {}

    function testTo2Felt() public {
        uint256 value = 0x1234567890123456789012345678901234567890123456789012345678901234;
        (Felt _amount_high, Felt _amount_low) = value.to2Felt();
        require(Felt.unwrap(_amount_high) == 0x1);
        require(Felt.unwrap(_amount_low) == 0x234567890123456789012345678901234567890123456789012345678901234);

        value = 0x2;
        (_amount_high, _amount_low) = value.to2Felt();
        require(Felt.unwrap(_amount_high) == 0x0);
        require(Felt.unwrap(_amount_low) == 0x2);
    }

    function testToUint256() public {
        Felt _amount_high = Felt.wrap(0x1);
        Felt _amount_low = Felt.wrap(0x234567890123456789012345678901234567890123456789012345678901234);
        uint256 value = FeltLibrary.toUint256(_amount_high, _amount_low);
        require(value == 0x1234567890123456789012345678901234567890123456789012345678901234);
        _amount_high = Felt.wrap(0x0);
        _amount_low = Felt.wrap(0x2);
        value = FeltLibrary.toUint256(_amount_high, _amount_low);
        require(value == 0x2);
    }
}
