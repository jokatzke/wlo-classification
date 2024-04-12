{ dockerTools, wlo-classification }:
dockerTools.buildLayeredImage {
  name = wlo-classification.pname;
  tag = wlo-classification.version;
  config.Cmd = [ "${wlo-classification}/bin/wlo-classification" ];
}
