// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/UnsafeUpgrades.sol";

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {Greeter} from "./contracts/Greeter.sol";
import {GreeterProxiable} from "./contracts/GreeterProxiable.sol";
import {GreeterV2} from "./contracts/GreeterV2.sol";
import {GreeterV2Proxiable} from "./contracts/GreeterV2Proxiable.sol";
import {WithConstructor, NoInitializer} from "./contracts/WithConstructor.sol";

/**
 * @dev Tests for the UnsafeUpgrades library.
 */
contract UnsafeUpgradesTest is Test {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function testUUPS() public {
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(new GreeterProxiable()),
            abi.encodeCall(Greeter.initialize, ("hello"))
        );
        Greeter instance = Greeter(proxy);
        address implAddressV1 = Upgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2Proxiable()),
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = Upgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testTransparent() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            address(new Greeter()),
            msg.sender,
            abi.encodeCall(Greeter.initialize, ("hello"))
        );
        Greeter instance = Greeter(proxy);
        address implAddressV1 = Upgrades.getImplementationAddress(proxy);
        address adminAddress = Upgrades.getAdminAddress(proxy);

        assertFalse(adminAddress == address(0));

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2()),
            abi.encodeCall(GreeterV2.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = Upgrades.getImplementationAddress(proxy);

        assertEq(Upgrades.getAdminAddress(proxy), adminAddress);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testBeacon() public {
        address beacon = UnsafeUpgrades.deployBeacon(address(new Greeter()), msg.sender);
        address implAddressV1 = IBeacon(beacon).implementation();

        address proxy = UnsafeUpgrades.deployBeaconProxy(beacon, abi.encodeCall(Greeter.initialize, ("hello")));
        Greeter instance = Greeter(proxy);

        assertEq(Upgrades.getBeaconAddress(proxy), beacon);

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeBeacon(beacon, address(new GreeterV2()), msg.sender);
        address implAddressV2 = IBeacon(beacon).implementation();

        GreeterV2(address(instance)).resetGreeting();

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testUpgradeProxyWithoutCaller() public {
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(new GreeterProxiable()),
            abi.encodeCall(GreeterProxiable.initialize, ("hello"))
        );

        Vm vm = Vm(CHEATCODE_ADDRESS);
        vm.startPrank(msg.sender);
        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2Proxiable()),
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ())
        );
        vm.stopPrank();
    }

    function testUpgradeBeaconWithoutCaller() public {
        address beacon = UnsafeUpgrades.deployBeacon(address(new Greeter()), msg.sender);

        Vm vm = Vm(CHEATCODE_ADDRESS);
        vm.startPrank(msg.sender);
        UnsafeUpgrades.upgradeBeacon(beacon, address(new GreeterV2()));
        vm.stopPrank();
    }

    function testWithConstructor() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            address(new WithConstructor(123)),
            msg.sender,
            abi.encodeCall(WithConstructor.initialize, (456))
        );
        assertEq(WithConstructor(proxy).a(), 123);
        assertEq(WithConstructor(proxy).b(), 456);
    }

    function testNoInitializer() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(address(new WithConstructor(123)), msg.sender, "");
        assertEq(WithConstructor(proxy).a(), 123);
    }
}
