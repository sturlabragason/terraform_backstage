resource "null_resource" "build" {
  provisioner "local-exec" {
    command = <<EOF
        ls
        nvm use 16
        export NODE_OPTIONS="--max-old-space-size=8192"
        cd backstage
        yarn install -g
        yarn install --frozen-lockfile
        yarn tsc
        yarn build
    EOF
  }
}