// Wildfire Black Mesa Roleplay
// File description: BMRP shared testing entity entity script
// Copyright (c) 2022 KiwifruitDev
// Licensed under the MIT License.
//*********************************************************************************************
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//*********************************************************************************************

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Flare"
ENT.Category = "Wildfire BMRP"

ENT.Spawnable = true
ENT.AdminOnly = true


function ENT:SetupDataTables()
    self:NetworkVar("Boolean", 0, "Active")
    self:NetworkVar("Entity", 0, "Flare")
    if SERVER then
        self:SetActive(false)
    end
end

