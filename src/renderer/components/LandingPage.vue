<template>
  <div>
    <el-container>
      <el-main>
        <el-row :gutter="20">
          <el-col :span="20">
            <el-upload
              class="upload-png"
              ref="upload"
              drag
              :multiple="false"
              :auto-upload="false"
              :show-file-list="false"
              list-type="picture"
              :on-change="fileChange"
              action=""
            >
              <i class="el-icon-upload"></i>
              <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
            </el-upload>
            <div v-if="dialogImageUrl">
              <div class="image-container">
                <img class="image" :src="dialogImageUrl" alt="">
              </div>
              <div class="btn-container">
                <el-button class="generator-btn" type="primary" icon="el-icon-download" @click="generator" v-loading.fullscreen.lock="fullscreenLoading">生成</el-button>
              </div>
            </div>
          </el-col>
        </el-row>
      </el-main>
    </el-container>
  </div>
</template>

<script>
import Jimp from 'jimp'
import icongen from 'icon-gen'
import fs from 'fs'
export default {
  name: 'landing-page',
  data () {
    return {
      fullscreenLoading: false,
      pngSizes: [16, 24, 32, 48, 64, 128, 256],
      dialogImageUrl: '',
      input: '',
      output: '',
      png: '',
      win: '',
      mac: ''
    }
  },
  methods: {
    open (link) {
      this.$electron.shell.openExternal(link)
    },
    generator () {
      let vm = this
      vm.$electron.ipcRenderer.send('open-file-dialog')
      vm.$electron.ipcRenderer.on('selected-directory', function (event, path) {
        vm.output = path[0] + '/icon-generator/'
        vm.png = vm.output + 'png/'
        vm.win = vm.output + 'win/'
        vm.mac = vm.output + 'mac/'
        vm.fullscreenLoading = true
        vm.createPNGs(0)
      })
    },
    fileChange (file, fileList) {
      this.dialogImageUrl = URL.createObjectURL(file.raw)
      this.input = file.raw.path
    },
    createPNGs (position) {
      let vm = this
      console.log(this.pngSizes)
      vm.createPNG(vm.pngSizes[position], function (err, info) {
        console.log(info)
        if (err) {
          if (err) throw new Error(err)
        } else if (position < vm.pngSizes.length - 1) {
          // keep going
          vm.createPNGs(position + 1)
        } else {
          // done, generate the icons
          icongen(vm.png, vm.mac, {type: 'png', names: 'icon', icns: {name: 'icns', sizes: vm.pngSizes}, report: true})
            .then((results) => {
              icongen(vm.png, vm.win, {type: 'png', names: 'icon', ico: {name: 'icns', sizes: vm.pngSizes}, report: true})
                .then((results) => {
                  // rename the PNGs to electron format
                  console.log('Renaming PNGs to Electron Format')
                  vm.renamePNGs(0)
                })
                .catch((err) => {
                  if (err) throw new Error(err)
                })
            })
            .catch((err) => {
              if (err) throw new Error(err)
            })
        }
      })
    },
    renamePNGs (position) {
      let vm = this
      var startName = vm.pngSizes[position] + '.png'
      var endName = vm.pngSizes[position] + 'x' + vm.pngSizes[position] + '.png'
      fs.rename(vm.png + startName, vm.png + endName, function (err) {
        console.log('Renamed ' + startName + ' to ' + endName)
        if (err) {
          throw err
        } else if (position < vm.pngSizes.length - 1) {
          // not done yet. Run the next one
          vm.renamePNGs(position + 1)
        } else {
          vm.fullscreenLoading = false
          vm.$notify({
            title: '成功',
            message: vm.output,
            type: 'success'
          })
          vm.$electron.shell.showItemInFolder(vm.output)
          console.log('\n ALL DONE')
        }
      })
    },
    createPNG (size, callback) {
      let vm = this
      var fileName = size.toString() + '.png'
      // make dir if does not exist
      if (!fs.existsSync(vm.output)) {
        fs.mkdirSync(vm.output)
      }
      // make sub dir if does not exist
      if (!fs.existsSync(vm.win)) {
        fs.mkdirSync(vm.win)
      }

      if (!fs.existsSync(vm.mac)) {
        fs.mkdirSync(vm.mac)
      }
      // make dir if does not exist
      if (!fs.existsSync(vm.png)) {
        fs.mkdirSync(vm.png)
      }
      Jimp.read(vm.input, function (err, image) {
        if (err) {
          callback(err, null)
        }
        image.resize(size, size)
          .write(vm.png + fileName, function (err) {
            var logger = 'Created ' + vm.png + fileName
            callback(err, logger)
          })
      }).catch(function (err) {
        callback(err, null)
      })
    }
  }
}
</script>

<style>
@import url("https://fonts.googleapis.com/css?family=Source+Sans+Pro");

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: "Source Sans Pro", sans-serif;
}

.image-container {
  background-color: #fff;
  border: 1px dashed #d9d9d9;
  border-radius: 6px;
  box-sizing: border-box;
  width: 360px;
  height: 180px;
  text-align: center;
  position: relative;
  overflow: hidden;
}

.image {
  position:absolute;
	top:0;
	bottom:0;
	left:0;
	right:0;
	margin:auto;
  width: 50%;
  max-width: 360px;
  max-height: 180px;
  display: block;
}

.btn-container {
  width: 360px;
}
.generator-btn {
  float: right;
  margin-top: 10px;
}
</style>
