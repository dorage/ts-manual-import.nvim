import "source-only";
import A from "default-only";
import B, { useB } from "default-with-a-module";
import C, { useC, useCC } from "default-with-modules";
import { useD } from "a-module";
import { useE, useEE } from "modules";
