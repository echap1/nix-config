# Disk layout (modules/disko): erases /dev/nvme0n1
{
  imports = [ ../../modules/disko ];
  disk = {
    device = "/dev/nvme0n1";
    encrypt = true;
  };
}
